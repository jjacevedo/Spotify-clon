# Architecture: Tunehold (a rebuild of the original's core features)

Final, 2026-10-04; revised 2026-10-05 after three design reviews (schema and data, security, mobile). Every finding and its verdict is in the Review log at the end. `/replica-architect` phase. Inputs: `recon.md` (S01–S27, F01–F12, data model), `features.csv`, `fixes.md` (sections 5 and 7), `deferred.md`, `brand.md`, `design/tokens.json`, `launch/landing.md`, and the stack chosen by the judge pass over three proposals (Proposal 1 "managed default" as the base, with grafts from the other two).

**Scope.** Personal use by the founder and a few friends. Accounts are by invite. No payments, plans, pricing, legal workflows, store listings or sharing between accounts (`deferred.md`). An admin-set storage limit per user replaces plans. Web, iOS and Android from the start.

**In one line.** A pnpm/Turborepo TypeScript monorepo. Next.js on Vercel Hobby serves the landing page, the web app and a REST API. An Expo SDK 58 app covers iOS and Android. Supabase Free provides Postgres (with row level security for the API role) and Auth. Audio goes in a private Backblaze B2 bucket and moves only through presigned URLs that fix its length, so no audio byte ever passes through Vercel.

All costs and durations in this document are **estimates**. Sources are listed at the end.

---

## Stack

| layer | choice | why |
| --- | --- | --- |
| monorepo | pnpm workspaces + Turborepo; TypeScript `strict` everywhere; Node 22 LTS | One install, one typecheck and one CI. Web and mobile share the API contract, the queue/shuffle engine and the tokens. |
| web app | Next.js (current stable, App Router) + React, one Vercel project | The landing page, app, REST API and sweep route ship in one deploy on one domain. |
| web UI | Tailwind CSS v4 themed from `replica/design/tokens.json`; Radix UI primitives; TanStack Virtual; dnd-kit | Tokens stay the single source. Radix provides keyboard and ARIA behaviour (AA, constraint T7). Virtualised lists handle 50k rows. dnd-kit handles drag reorder. |
| mobile app | Expo SDK 58 + expo-router, EAS development builds; StyleSheet with a theme from `packages/tokens`; FlashList; expo-image (`cacheKey` = cover id) | This was the founder's choice. Background audio needs config plugins, so Expo Go won't do. SDK 58 is required (see mobile playback): stable if it has shipped by milestone 1b, otherwise the `next` tag pinned exactly (expo 58.0.3, expo-audio 58.0.5 on 2026-10-04). |
| API | Next.js Route Handlers under `/api/v1`, REST + JSON; zod schemas and a typed fetch client in `packages/contract` | One API for both clients, validated at the edge (constraint T2). |
| client data | TanStack Query on web and mobile (persisted on mobile) | Caching, retries and optimistic favorites and reorders, without custom plumbing. |
| database | Supabase Postgres, Free plan, two projects (dev, prod), with `pg_trgm` and `unaccent`. Neon Free is the documented swap. | $0. About 2 KB per track with indexes and a capped `tags_raw` (estimate built on a measured 1.1 KB base): ~50 MB for the 25k-track cost assumption, ~300 MB for three 50k-track libraries, against the 500 MB cap (see "Large libraries"). |
| ORM + migrations | Drizzle ORM for typed queries; plain-SQL migrations in `packages/db/migrations` applied by `drizzle-kit migrate`; postgres.js through the Supavisor transaction pooler (port 6543, `prepare: false`). Two roles: `tunehold_app` for API requests, the owner (`postgres`) for jobs, the sweep, admin routes and migrations. | Typed SQL that stays close to `schema.sql`. The pooler suits serverless functions. |
| access rules | **Row level security with real policies**, plus owner-scoped repositories. The API connects as `tunehold_app` (`NOBYPASSRLS`) and runs each request in one transaction that starts with `select set_config('app.uid', <JWT sub>, true)`. Every owner table has an `owner_id = app_uid()` policy. Also: the Data API off, composite owner foreign keys, and a second-user suite generated from the route table. | A missed owner filter on a read still returns only the caller's rows. The setting is transaction-local, so it is safe through the transaction pooler. |
| auth | Supabase Auth (email + password), sign-ups disabled, settings checked in (see "Auth settings"). The admin creates invites with `auth.admin.generateLink`. Web uses cookies (`@supabase/ssr`). Mobile sends a Bearer token, verified with `getClaims` (asymmetric JWT signing keys on). Every request is also refused when its JWT `session_id` belongs to a revoked device. | Managed, free, and invite-only out of the box. |
| email | None in v1: the admin shares invite and reset links by chat. Resend Free becomes Supabase's custom SMTP once a domain exists. | Supabase's default SMTP only reaches the project's team members. |
| payments | **Deferred, see `deferred.md`.** | Personal use. An admin-set storage limit replaces plans. |
| files | Backblaze B2 private bucket (us-east) through the S3-compatible API, with presigned PUT and GET. Every presigned PUT and part fixes Content-Length, Content-Type and Content-MD5 in the signature. Cloudflare R2 is a swap through env vars in `packages/storage`. | Storage dominates the cost: about $2.3/month for 343 GB on B2 vs about $5.0 on R2. Egress stays inside B2's free 3× allowance. Each user has their own copies, with no cross-user deduplication. The signed length binds stored bytes to reserved bytes. |
| upload (web) | `@uppy/core` + `@uppy/aws-s3` used headless, with every signature from our API. A single PUT under 32 MB, multipart with 16 MB parts above that. MD5 per file with `hash-wasm` in a Web Worker. Folders are read with `webkitGetAsEntry`; on Chromium, `showDirectoryPicker` keeps the folder handle in IndexedDB. | Resumable S3 multipart without writing the protocol ourselves. The web is the place for big imports. |
| upload (mobile) | `expo-file-system`: `File.pickFileAsync` / `Directory.pickDirectoryAsync`, `file.info({ md5: true })`, `file.createUploadTask(url, { httpMethod: 'PUT' })`. Always a single PUT. A transfer queue saved in `expo-sqlite`, at most 3 tasks in flight, each URL signed just before its task starts. | First-party, and the MD5 is computed natively for large FLAC files. Transfers are foreground-first: Android runs them inside the app process, and iOS doesn't hand a background task back to JS after the app is killed, so the app reconciles on every launch (see "Mobile transfers"). |
| tags + covers | `music-metadata` 12 + `@tokenizer/s3` range reads, `file-type` magic-byte sniffing over the same range tokenizer, `sharp` for 600/300 px WebP covers, in a Node route or job on Vercel, with resource limits (see "Parsing untrusted files") | Reads only the header bytes, MP4 tails included. Full Node runtime with no per-request CPU cap. One code path for web and mobile uploads. |
| jobs | A Postgres `jobs` table (`FOR UPDATE SKIP LOCKED`), run inline through `next/server` `after()`. A **GitHub Actions** schedule calls the sweep route hourly and takes a nightly, `age`-encrypted `pg_dump` into a B2 backups bucket. The Vercel daily cron is a second trigger. | Hobby cron runs only once a day. Supabase Free has no usable backups and pauses after a week idle. Actions minutes are free (see Costs for the private-repo budget). |
| transcoding | None in v1: originals are streamed. Later and optional: `workers/transcode` (Node + ffmpeg) claiming jobs from Postgres. | MP3, AAC, FLAC and WAV play natively on every target. The stored original is never touched. |
| web playback | Own engine on `HTMLAudioElement` (current track plus a preloaded next one). Media Session API. A Zustand store driven by `packages/player-core`. `PlayerProvider` in the root `(app)` layout. On iOS Safari, a single element whose `src` is swapped on `ended` (to verify). | No dependency, and navigation never stops playback (constraint T5). iOS can block `play()` on a second element while the screen is locked. |
| mobile playback | `expo-audio` 58 `AudioPlaylist` with an append-only rolling window fed by `player-core`; `setActiveForLockScreen` with `showNextTrack` / `showPreviousTrack`; `setAudioModeAsync({ playsInSilentMode: true, shouldPlayInBackground: true, interruptionMode: 'doNotMixPersistent' })`; plugin `['expo-audio', { enableBackgroundPlayback: true, recordAudioAndroid: false, microphonePermission: false }]`. Error recovery through a small `pnpm patch` of expo-audio, or by rebuilding the playlist (see "Mobile player adapter"). | First-party. Lock-screen next/previous exists only on `AudioPlaylist`, and only from SDK 58: SDK 57 is not a fallback. `react-native-track-player` v5 is not ready either: npm `latest` is 4.1.2, and v5 is alpha nightlies only (the last one is dated 2025-09-24). |
| queue / shuffle / resume | `packages/player-core`: a pure-TS state machine. The user queue plays before the context. F2 stop-at-end. Repeat off/all/one. Once-per-cycle shuffle by the keyed hash `md5(seed:memberId)`. One `playback_state` row per user, written only by the active device; queue edits are server-side ops from any device. | Satisfies F4: the shuffle state is three values, survives device switches and edits, and the same order is computed in SQL (online) and on the device (offline). |
| streaming URLs | Batched presigned B2 GETs (`/tracks/stream-urls?ids=`) with a 2 h TTL, re-signed before they can expire mid-track, and at most twice per track per 10 minutes after an error. Covers are signed per UTC day, so their URLs stay stable and cacheable. | Audio is never public (constraint T3), Vercel never proxies audio, and disabling a user or a track takes effect within 2 h. |
| offline (mobile) | `File.createDownloadTask` into `Paths.document/tunehold/audio`, verified by size and MD5, then registered per device. `expo-sqlite`, opened inside the backup-excluded folder, holds the offline index (files linked to the scopes that need them), a catalog mirror (from `GET /sync`), the play-event outbox, the device id and the Supabase session. Relative file names only. A local backup-exclude module on iOS; on Android `allowBackup=false` plus `dataExtractionRules`. Wi-Fi-only downloads by default. | Satisfies F5: downloads aren't purgeable and are verified, the app is browsable in airplane mode, copies are removed at the next connection, and a restored or migrated phone starts clean. |
| search | `pg_trgm` + `unaccent` over generated `search_text` columns with GIN indexes, always filtered by `owner_id`; each query word escaped for `LIKE` | Covers F06's accent, case and partial-word cases with no search vendor. |
| landing page | `apps/web/app/(marketing)/page.tsx` at `/`, `force-static`, server components only | Same host and domain. It is the first code task. |
| export | Route handlers streaming M3U8 (zipped), CSV and history CSV, reading in short keyset pages; CSV cells and file names sanitised | The export part of F7. The outputs are small, so no job is needed. |
| hosting | Vercel Hobby, functions in `iad1`, next to Supabase `us-east-1` and B2 us-east | $0. Hobby is for "personal, non-commercial" use, which matches `deferred.md`. |
| mobile builds | EAS Build Free. Android: internal-distribution APK. iOS: TestFlight internal testing (friends added as App Store Connect users) once the Apple Developer Program is paid. iOS bundle id and Android package frozen as `app.tunehold.mobile` before the first build. | $0 until iOS distribution is worth paying for. EAS cloud builds need no Mac. Changing the id later means a new app, a reinstall and lost downloads. |
| testing + CI | Vitest (packages, repositories, the second-user suite generated from the route table, concurrency tests for the storage counters), Playwright (web e2e, Chromium at `/opt/pw-browsers`), GitHub Actions (lint, typecheck, test, db tests, e2e, sweep gate), and an on-device checklist with failure drills | Evidence over claims (process constraint 5). |
| Subsonic-compatible API | Not in v1. An optional, founder-triggered milestone (see "Subsonic and cars"). | The schema keeps stable per-user artist, album and track ids, so it stays cheap to add. |

### Dependencies (approved by this document)

Anything not listed needs a spec line or a BLOCKED report (process constraint 4). The review revision added no package: `pnpm patch` is built into pnpm, `import 'server-only'` is resolved by Next.js itself, and the backup workflow installs the `age` CLI on the runner with apt.

| where | packages | why |
| --- | --- | --- |
| all | `typescript`, `turbo`, `eslint`, `prettier`, `vitest`, `zod` | Toolchain and validation. |
| `apps/web` | `next`, `react`, `react-dom`, `tailwindcss` (v4), `@radix-ui/react-*`, `@tanstack/react-query`, `@tanstack/react-virtual`, `@dnd-kit/core`, `@dnd-kit/sortable`, `zustand`, `@supabase/ssr`, `@supabase/supabase-js`, `@uppy/core`, `@uppy/aws-s3`, `hash-wasm`, `client-zip`, `@playwright/test` (dev) | Stack table. `client-zip` streams the playlists export zip. |
| `apps/mobile` | `expo`, `expo-router`, `expo-audio`, `expo-file-system`, `expo-sqlite`, `expo-image`, `expo-network` (Wi-Fi vs cellular), `expo-crypto` (`randomUUID`), `@shopify/flash-list`, `@supabase/supabase-js`, `@tanstack/react-query` + its persister, `eas-cli` (dev) | Stack table. The Supabase session is stored through a small storage adapter over the backup-excluded `expo-sqlite` database. |
| `packages/db` | `drizzle-orm`, `postgres`, `drizzle-kit` (dev), `supabase` CLI (dev, local stack for tests) | Database access and migrations. |
| `packages/storage` | `@aws-sdk/client-s3`, `@aws-sdk/s3-request-presigner` | S3 API against B2 or R2. |
| `packages/media` | `music-metadata`, `@tokenizer/s3`, `file-type`, `sharp` | Extraction, sniffing and covers. |
| `packages/player-core` | `js-md5`, `fractional-indexing` | The shuffle key must equal Postgres `md5()` on every client (Hermes has no WebAssembly, so `hash-wasm` won't run there). `fractional-indexing` gives order keys for playlist reorder and rebalance. |

### Environment variables

Secrets live in Vercel, EAS and GitHub environments, never in the repo (constraint T9). Each package documents the variables it reads in its `.env.example`.

| name | where | what |
| --- | --- | --- |
| `DATABASE_URL` | web (server) | Supavisor **transaction** pooler, port 6543, role `tunehold_app` (RLS applies). Every member request uses it. |
| `DATABASE_URL_OWNER` | web (server: jobs, sweep, admin routes) | Same pooler, owner role (bypasses RLS). Never used by member request handlers; a lint rule keeps it inside `src/server/jobs`, `src/server/admin` and the sweep route. |
| `DATABASE_URL_DIRECT` | CI, migrations, backup | Supavisor **session** pooler, port 5432. It is IPv4-reachable, unlike the direct host, which GitHub runners can't reach. |
| `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | web | Auth client |
| `SUPABASE_SECRET_KEY` | web (server only) | `auth.admin.*` for invites, recovery links, bans and user purge |
| `EXPO_PUBLIC_SUPABASE_URL`, `EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY`, `EXPO_PUBLIC_API_BASE_URL` | mobile | Auth client and API origin |
| `S3_ENDPOINT`, `S3_REGION`, `S3_BUCKET`, `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY` | web (server) | B2 application key restricted to the audio bucket |
| `BACKUP_S3_BUCKET`, `BACKUP_S3_ACCESS_KEY_ID`, `BACKUP_S3_SECRET_ACCESS_KEY`, `BACKUP_AGE_RECIPIENT` | GitHub Actions only (Environment `production`) | A separate key that can only write to the backups bucket, and the `age` public key that encrypts the dump (the private key stays offline with the founder) |
| `APP_ORIGIN` | web | e.g. `https://tunehold.vercel.app`. Used for invite links, the Origin check, the CSP and bucket CORS. |
| `CRON_SECRET` | web, GitHub Actions | Bearer token for `/api/cron/sweep`. At least 32 characters; the route fails at startup without it and compares with `crypto.timingSafeEqual`. |
| `ADMIN_EMAIL` | seed script | The founder's account, created with `role = 'admin'` |
| `MAX_FILE_BYTES` (1 GiB), `MULTIPART_THRESHOLD_BYTES` (32 MiB), `PART_SIZE_BYTES` (16 MiB), `COVER_MAX_BYTES` (10 MiB), `UPLOAD_URL_TTL_SECONDS` (3600), `UPLOAD_SESSION_TTL_HOURS` (72), `UPLOAD_SESSION_MAX_DAYS` (7), `STREAM_URL_TTL_SECONDS` (7200), `MANIFEST_URL_TTL_SECONDS` (21600), `PURGE_GRACE_MINUTES` (10), `EXTRACT_PARSE_TIMEOUT_SECONDS` (120) | web (server) | Tunables. Defaults are shown in brackets. |

**Scoping.** The production values of `DATABASE_URL*`, `S3_*`, `SUPABASE_SECRET_KEY` and `CRON_SECRET` live only in Vercel's Production environment. Preview deployments point at the dev Supabase project and the dev bucket. In GitHub, the production secrets live in an Environment `production` restricted to the deploy branch and to the `schedule` and `workflow_dispatch` triggers. No workflow uses `pull_request_target`.

---

## Repo layout

```
tunehold (current repo root; replica/ and .claude/ stay as they are)
├─ package.json · pnpm-workspace.yaml · turbo.json · .npmrc · tsconfig.base.json · .env.example
├─ supabase/config.toml        local stack + the checked-in Auth settings (see "Auth settings")
├─ patches/                    only if the expo-audio patch path is taken (pnpm patch)
├─ .github/workflows/
│  ├─ ci.yml                 lint · typecheck · test · db tests (postgres:17 service) · build · e2e · sweep gate
│  ├─ sweep.yml              hourly: curl -H "Authorization: Bearer $CRON_SECRET" $APP_ORIGIN/api/cron/sweep
│  └─ backup.yml             nightly 03:00 UTC: pg_dump via the session pooler | age → B2 backups bucket
├─ apps/
│  ├─ web/                                  Next.js App Router, one Vercel project (region iad1)
│  │  ├─ middleware.ts                      CSP nonce and security headers for app routes
│  │  ├─ app/(marketing)/page.tsx           landing at "/" (force-static, light tokens). FIRST CODE TASK
│  │  ├─ app/(auth)/login/page.tsx          S03
│  │  ├─ app/(auth)/welcome/page.tsx        set a password after an invite link (replaces S02)
│  │  ├─ app/(auth)/reset/page.tsx          S04: set a new password after a recovery link
│  │  ├─ app/auth/confirm/route.ts          GET: a "Continue" page, no side effects; POST: verifyOtp → cookie → /welcome or /reset
│  │  ├─ app/(app)/layout.tsx               shell: sidebar or bottom nav, <PlayerProvider>, S12 bar, S13, S14
│  │  ├─ app/(app)/home · search · library · favorites · playlist/[id] · album/[id] · artist/[id]
│  │  │            · upload · history · settings · admin                (S05 S06 S07 S08 S09 S10 S11 S18 S21 + admin)
│  │  ├─ app/api/v1/**/route.ts             REST for web and mobile (see API)
│  │  ├─ app/api/cron/sweep/route.ts        CRON_SECRET-protected sweep
│  │  ├─ src/server/                        `import 'server-only'`; auth context, request transaction, repositories, services, jobs, admin
│  │  ├─ src/player/                        HTMLAudio engine + Media Session adapter over @tunehold/player-core
│  │  ├─ src/upload/                        Uppy wiring, MD5 worker, folder walker
│  │  ├─ src/marketing/status.ts            "Works today" / "In progress" flags for the landing cards
│  │  ├─ e2e/                               Playwright specs per flow (F01–F06, F10 by admin link)
│  │  └─ vercel.json                        region iad1, daily cron → /api/cron/sweep
│  └─ mobile/                               Expo SDK 58 app (expo-router, EAS)
│     ├─ app/(tabs)/home · search · library · upload ; app/player.tsx · queue.tsx
│     │   · playlist/[id].tsx · album/[id].tsx · artist/[id].tsx · favorites.tsx · downloads.tsx
│     │   · settings.tsx · login.tsx
│     ├─ src/player/                        expo-audio adapter: append-only window, recovery, lock screen, local-first sources
│     ├─ src/offline/                       expo-sqlite schema (mirror, index with scope links, outbox, session), sync, tombstones
│     ├─ src/transfers/                     transfer queue (uploads and downloads), launch reconcile
│     ├─ src/upload/                        pick files or a folder, native MD5
│     ├─ modules/backup-exclude/            local Expo module: iOS isExcludedFromBackup on the tunehold folder
│     ├─ plugins/withDataExtractionRules.ts local config plugin: Android backup and device-transfer exclusions
│     ├─ app.config.ts                      expo-audio plugin { enableBackgroundPlayback: true, recordAudioAndroid: false,
│     │                                     microphonePermission: false }; android.allowBackup=false;
│     │                                     iOS bundle id and Android package app.tunehold.mobile (frozen)
│     └─ eas.json                           development · preview (Android APK, internal) · testflight
├─ packages/
│  ├─ contract/      zod schemas for every /api/v1 route, error codes, smart-rule grammar, typed fetch client
│  ├─ db/            Drizzle table definitions, migrations/0000_init.sql (= replica/schema.sql), seed.ts, repository tests
│  ├─ player-core/   queue, repeat, F2 end rule, once-per-cycle shuffle, PlaybackState reducer, window planner, codec gate
│  ├─ media/         extraction, sniffing, covers, name and sort keys, tags allow-list, path heuristics, M3U8/CSV writers, safe names
│  ├─ storage/       S3 client (B2 default, R2 by env): presign PUT/GET with fixed length, multipart, list parts, head, range read, delete all versions
│  ├─ tokens/        build script: tokens.json → Tailwind v4 @theme CSS (web) + RN theme object (mobile)
│  └─ config/        tsconfig (strict), eslint and prettier presets (incl. the import boundaries below)
└─ workers/transcode/   LATER, optional: Node + ffmpeg container claiming transcode jobs (not created in v1)
```

Package names are `@tunehold/<name>`. App identifiers use `tunehold`, never the original's name (constraint 2). The deploy gate runs `sweep.py` on `apps/web` (including `public/`), `apps/mobile` and `packages`, and each run must exit 0.

**Import boundaries (ESLint `no-restricted-imports`).** `@tunehold/db` and `@tunehold/storage` may be imported only from `apps/web/src/server/**` and `app/api/**`; the owner database client only from `src/server/jobs`, `src/server/admin` and the sweep route. `import 'server-only'` sits at the top of `apps/web/src/server/*` modules (not inside `packages/*`, where it would break Vitest and scripts).

---

## Schema

**Tables: 17. Access rules: row level security with policies for the API role** (`tunehold_app`), plus owner-scoped repositories. Jobs, the sweep and admin routes use the owner connection. The full SQL is in [`replica/schema.sql`](schema.sql), which becomes migration `0000_init.sql`.

**Validation status.** The previous revision was executed on 2026-10-04 by the design review on PostgreSQL 16.14 (`ON_ERROR_STOP`, `--single-transaction`): the schema, the Supabase role branch against stand-in roles and `auth.users`, and a `pg_dump -Fc` / `pg_restore` round trip all passed. **This revision has not been executed** (no shell or Postgres in the session that wrote it). The first task that adds `packages/db` runs it on postgres:17 and passes the checks below before milestone 1a starts.

**Schema checks before 1a** (Vitest against a throwaway postgres:17, in `pnpm test:db`):
1. `psql -v ON_ERROR_STOP=1 --single-transaction -f replica/schema.sql` on an empty database; the same on `supabase start` (Supabase branch, `auth.users` key).
2. Counters: reserve → complete → purge → profile delete keeps `used_bytes` and `reserved_bytes` exact; a reserve and the reconcile run concurrently without drift or a failed CHECK.
3. RLS: as `tunehold_app` with `app.uid` = A, every owner table returns only A's rows, and an insert with B's `owner_id` fails; with `app.uid` unset nothing is visible.
4. Sync: a 15,000-row bulk insert in one transaction pages to the end with the keyset cursor.
5. Library lock: `library_cleanup` and an extract-style re-point of an empty album, run concurrently, never leave a `ready` track with `album_id` NULL.
6. A 300-character CJK title inserts with every index in place.
7. Playlist rebalance with `SET CONSTRAINTS playlist_items_order_key DEFERRED`.
8. A play-events batch containing a purged track id and another user's device id inserts every event (`orphaned` / NULL device) without an error.
9. `pg_dump -Fc` / `pg_restore` round trip, with `tunehold_app` created first.

| table | owner column | what it holds | notes |
| --- | --- | --- | --- |
| `profiles` | `id` (= auth user) | role, status, storage limit, `used_bytes`, `reserved_bytes`, settings | The counters are written only by triggers on `tracks` and `upload_sessions`. FK to `auth.users` `on delete restrict`, added only on Supabase. |
| `invites` | `profile_id` | who invited whom, link regenerations, acceptance | |
| `devices` | `owner_id` | one row per install or browser sign-in; its Supabase `auth_session_id`; cellular-download switch; remote revoke | The id is generated on the device at every sign-in and after every wipe. A revoked device's session is refused on every route. |
| `covers` | `owner_id` | one row per distinct image per user; 600 and 300 px WebP keys | Deduplicated by sha256 within a user; objects keyed by the row id. |
| `artists` | `owner_id` | per-user artists, `name_key` for grouping, `sort_name`, `search_text` | **Tables, not views:** stable ids, one row for cover and year, grouping decided once at ingest. |
| `albums` | `owner_id` | per-user albums keyed `(owner, album artist, title_key)`, sort keys | `unique nulls not distinct`, because the album artist can be unknown. |
| `tracks` | `owner_id` | one uploaded file: immutable object key, size, MD5, sniffed MIME, audio properties, effective tags (≤ 300 chars), capped raw tags, sort keys, play count, status | `unique (owner_id, content_md5)` among rows that aren't deleted. Status values: `processing`, `ready`, `failed`, `disabled`, `deleted`. |
| `upload_sessions` | `owner_id` | one file in flight (audio or cover image): mode, multipart id, part MD5s, reserved bytes, expiry | One live session per file per user. Covers reserve bytes too and are `consumed` after use. Pruned 30 days after they finish. |
| `jobs` | `owner_id` (nullable) | the Postgres queue, with a `dedupe_key` | Claimed with `SKIP LOCKED`. |
| `playlists` | `owner_id` | name, description, kind (`manual`, `smart` + `rules`), custom cover | Rules ≤ 8 KB, fixed grammar. |
| `playlist_items` | `owner_id` | track in a playlist, ordered by a fractional `sort_key` (`COLLATE "C"`) | Reorder is one row update under the playlist row lock; rebalance past 64 chars. |
| `favorites` | `owner_id` | the recon's Like | Append-only (unfavoriting writes a tombstone; favoriting again deletes it). |
| `play_events` | `owner_id` | listening history: client UUID, UTC time, IANA zone, `ms_played`, counted flag, title snapshot | Append-only, idempotent, never blocked by a stale track or device. |
| `playback_state` | `owner_id` (PK) | active device, context, cursor, current item, position and time, playing flag, user queue, shuffle `{seed, cycle, last_key}`, repeat, version | See PlaybackState below. |
| `downloads` | `owner_id` | verified copies per device per track | The device keeps the scope links; the server keeps files and bytes. |
| `tombstones` | `owner_id` | hard deletes for offline devices | Kept 180 days. |
| `rate_limits` | none (key) | fixed-window counters per user or IP and route | Written only through `rate_limit_hit()`. |

No money, plan, entitlement or report tables. A `track_variants` table (for transcoded copies) and an `app_passwords` table (for Subsonic) are left for their optional milestones.

**Decisions inside the schema:**
- **Row level security for the API role.** `tunehold_app` has table grants and one policy per owner table (`owner_id = app_uid()`, where `app_uid()` reads the transaction-local `app.uid`). `profiles` and `invites` have self policies for select and update only; `rate_limits` has none. Supabase's `anon` and `authenticated` keep no grants. The role has `statement_timeout = 60s`, `idle_in_transaction_session_timeout = 30s` and, on PG17, `transaction_timeout = 90s`. Its login password is set per environment outside the repo.
- **Storage counters by trigger.** `AFTER INSERT OR DELETE ON tracks` moves `size_bytes` in and out of `used_bytes`. `AFTER INSERT OR UPDATE OF status, reserved_bytes OR DELETE ON upload_sessions` applies the delta of `reserved_bytes` whenever a session starts or stops holding bytes (`upload_session_holds_bytes(kind, status)`). Guard triggers make `tracks.owner_id`, `object_key`, `size_bytes`, `content_md5` and the session's `owner_id`, `kind`, `declared_size_bytes`, `reserved_bytes` immutable. The functions are `SECURITY DEFINER`, so RLS never hides the profile row from them.
- **Composite owner foreign keys.** Wherever a request names another row by id (playlist item → track, favorite → track, download → track and device, play event → track and device, playback state → current track and active device, track → album/artist/cover), the child carries `owner_id`, and the FK is on `(id, owner_id)`. A cross-user id fails in Postgres even on the owner connection. Nullable links use `ON DELETE SET NULL (column)` (Postgres 15+). Drizzle can't express that, so migrations are hand-written SQL and `drizzle-kit push` is never used.
- **`on delete` rules.** Deleting a profile cascades everything. A track's hard delete cascades its playlist items, favorites and downloads, and sets `play_events.track_id` to null (history keeps its snapshot). An artist is `restrict`ed while albums use it, because `library_cleanup` removes empty albums first.
- **Library writes are serialised per user.** Every transaction that upserts or points at albums, artists or covers (extract's grouping step, `apply_sidecar_cover`, `regroup_batch`, `PATCH /tracks/:id`, `PATCH /albums/:id`, cover PATCHes) and `library_cleanup` starts with `select pg_advisory_xact_lock(hashtextextended('library:' || $owner_id, 0))`. The xact variant is safe through the transaction pooler. Cover objects are keyed by row id, and cleanup deletes objects only after its row deletes commit.
- **Sort keys.** `sortKey()` in `packages/media`: NFD, combining marks removed, lower case, inner spaces collapsed, trimmed, first 100 code points. Stored as `text COLLATE "C"` (`tracks.sort_title`, `sort_artist`, `sort_album`; `albums.sort_title`, `sort_artist`; `artists.sort_name`) and sent to devices as-is, so server order, cursor comparisons and the device's SQLite `BINARY` order are the same bytes. `name_key` and `title_key` are `COLLATE "C"` too. `track_no` and `disc_no` are `NOT NULL DEFAULT 0` (0 = unknown).
- **Search.** `search_text` is generated as `lower(unaccent(...))`, using an IMMUTABLE wrapper so it can be indexed. Each GIN trigram index covers all users and is always combined with `owner_id = $1`. That is fine for a handful of users. At a public launch, revisit with `btree_gin` composite indexes.
- **Times.** Every column is `timestamptz` in UTC. `play_events.client_tz` (IANA) is the only local-time data, used only for history.
- **`(updated_at, id)` is the sync cursor** for the offline mirror. `updated_at` is set by triggers with `clock_timestamp()`. Append-only tables (`favorites`, `play_events`, `tombstones`) use `(created_at, id)`. The sync indexes are `(owner_id, updated_at, id)` (favorites: `(owner_id, created_at desc, id desc)`, scanned backwards; tombstones: `(owner_id, created_at, id)`).
- **Size caps.** Tag columns ≤ 300 characters (so no index row can pass Postgres' 2,704-byte limit); `tags_raw` ≤ 8 KB; smart-playlist `rules` ≤ 8 KB; `user_queue` ≤ 1,000 entries; `context_cursor` ≤ 2 KB; cover sessions ≤ 10 MiB.

### Key queries (the repository layer owns them; listed here so the backend and the tests agree)

```sql
-- Every member request (role tunehold_app): one transaction, caller first.
-- No network I/O (S3, Supabase admin, HTTP response writes) inside it.
begin;
select set_config('app.uid', $uid, true);
-- ... repository queries; RLS limits every owner table to the caller's rows ...
commit;

-- Storage limit, reserve gate (same transaction as the session inserts). The row
-- lock serialises a user's concurrent batches. No row back = account not active.
select used_bytes, reserved_bytes, storage_limit_bytes
  from profiles
 where id = $uid and status = 'active'
   for update;
-- then, per file in walk order: if used + reserved + size <= limit, insert the
-- session (the trigger adds its bytes to reserved_bytes and the app adds the size
-- to its running total), else answer 'storage_full' for that file.
insert into upload_sessions (id, owner_id, batch_id, kind, ..., declared_size_bytes, reserved_bytes, expires_at)
values ($sid, $uid, $batch, 'audio', ..., $size, $size, now() + interval '72 hours');

-- Settle at /complete (one transaction, after the storage checks ran outside it).
-- The triggers move the bytes from reserved_bytes to used_bytes.
insert into tracks (id, owner_id, object_key, size_bytes, content_md5, mime, title, sort_title, ...)
values (...);
update upload_sessions
   set status = 'completed', track_id = $tid, completed_at = now()
 where id = $sid and status = 'completing';

-- Every terminal transition (failed, aborted, expired, consumed) releases once:
update upload_sessions set status = $terminal
 where id = $sid and status in ('pending', 'completing')
returning id;

-- Reconcile (sweep, per user, its own owner-connection transaction). The lock is
-- taken first; the sums run in new statements, which see every transaction that
-- committed before the lock was granted. With the triggers, drift is a bug: log it.
select 1 from profiles where id = $uid for update;
select coalesce(sum(size_bytes), 0) from tracks where owner_id = $uid;
select coalesce(sum(reserved_bytes), 0) from upload_sessions
 where owner_id = $uid and upload_session_holds_bytes(kind, status);
-- if either differs: log both values, then
update profiles set used_bytes = $used, reserved_bytes = $reserved where id = $uid;

-- Sync page for one entity (keyset; never an overlap between pages)
select * from tracks
 where owner_id = $uid and (updated_at, id) > ($ts, $id)
 order by updated_at, id
 limit $room;

-- Natural order: next N in a library-by-artist context (all keys NOT NULL, "C")
select id, sort_artist, sort_album, disc_no, track_no
  from tracks
 where owner_id = $uid and status = 'ready'
   and (sort_artist, sort_album, disc_no, track_no, id) > ($1, $2, $3, $4, $5)
 order by sort_artist, sort_album, disc_no, track_no, id
 limit $n;

-- Once-per-cycle shuffle: next N of the whole library (memberId = track id; for a
-- playlist context memberId = playlist item id, so duplicates each get a key)
select t.id, md5($seed || ':' || t.id::text) collate "C" as k
  from tracks t
 where t.owner_id = $uid and t.status = 'ready'
   and ($last_key::text is null or md5($seed || ':' || t.id::text) collate "C" > $last_key)
 order by k
 limit $n;

-- Play events: set-based, never blocked by a purged track or a foreign device
insert into play_events (id, owner_id, track_id, device_id, played_at, ms_played, counted,
                         context_type, context_id, client_tz, track_title, artist_name, album_title)
select e.id, $uid, t.id, d.id, least(e.played_at, now()), e.ms_played,
       e.ms_played >= least(30000, coalesce(t.duration_ms, 60000) / 2),
       e.context_type, e.context_id, e.client_tz,
       coalesce(t.title, e.track_title), coalesce(t.artist_name, e.artist_name),
       coalesce(t.album_title, e.album_title)
  from jsonb_to_recordset($events) as e(id uuid, track_id uuid, device_id uuid, played_at timestamptz,
                                        ms_played integer, context_type text, context_id uuid,
                                        client_tz text, track_title text, artist_name text, album_title text)
  left join tracks t on t.id = e.track_id and t.owner_id = $uid
  left join devices d on d.id = e.device_id and d.owner_id = $uid
on conflict (id) do nothing
returning id, track_id, counted;
-- then, same transaction: play_count + 1 and last_played_at for the returned
-- counted rows whose track_id is not null.

-- Job claim (owner connection)
update jobs set status = 'running', locked_at = now(), locked_by = $worker, attempts = attempts + 1
 where id in (select id from jobs where status = 'queued' and run_after <= now()
               order by run_after limit $n for update skip locked)
returning *;
```

### PlaybackState (the spec `fixes.md` asks for before F4)

- **Members.** A context has an ordered set of members. Each member's key is a row of NOT NULL values compared bytewise, with the member id last; the cursor stores it as `{ "v": [...], "id": "..." }`. In natural order, "next" is the first member whose `(v..., id)` row is greater than the cursor. Edits mid-play don't break it: added members fall where their key says, and removed ones are simply not found. The same keys are in the device mirror, so offline "next" equals online "next".

  | context | member id | key (`v`, then id) | index |
  | --- | --- | --- | --- |
  | album | track | `disc_no, track_no, sort_title` | `tracks_album_order_idx` |
  | artist | track | `coalesce(year, 0), sort_album, disc_no, track_no` | `tracks_artist_order_idx` |
  | library, sort `added` | track | `created_at` | `tracks_owner_live_created_idx` |
  | library, sort `title` | track | `sort_title` | `tracks_owner_live_title_idx` |
  | library, sort `artist` | track | `sort_artist, sort_album, disc_no, track_no` | `tracks_owner_live_artist_idx` |
  | library, sort `album` | track | `sort_album, disc_no, track_no` | `tracks_owner_live_album_idx` |
  | playlist | playlist item | `sort_key` | `playlist_items_order_key` |
  | favorites | track | `created_at` of the favorite (newest first) | `favorites_owner_created_idx` |
  | search | track | position in `context_track_ids` (at most 1000, frozen) | — |

- **User queue.** "Play next" puts an entry at the front of `user_queue`; "Add to queue" puts it at the back. Entries play before the context resumes and are removed as they start. They don't move the context cursor or the shuffle state. Queue edits are server-side ops (`POST /playback-state/queue`) from any device, applied in one `UPDATE` with `version = version + 1`; the active device removes entries as they start by sending `consumedEntryIds` in its PUT.
- **Shuffle (F4).** Turning shuffle on draws a random 32-hex `seed`, with `cycle = 0` and `last_key = null`. The order is `md5(seed + ':' + memberId)`, ascending, compared bytewise. "Next" is the smallest key above `last_key`. When none is left, the cycle ends. With repeat **all**, `cycle + 1` starts with a new seed. With repeat **off**, the context ends (`ended = true`, F2). So no member repeats inside a cycle, and members added mid-cycle play this cycle or the next. "Reshuffle" means a new seed with `last_key = null`. If a new cycle's first member equals the last one played, `player-core` skips it to the end of that cycle. The web and online mobile clients get "next N" from `GET /contexts/:type/:id/tracks?order=shuffle`, computed in SQL. Offline, the device sorts the keys of its mirror once per seed (about 3 MB for 50k members, in chunks so the JS thread stays free) and binary-searches `last_key`. `js-md5` and Postgres `md5()` must give the same hex: Vitest checks this against fixed vectors.
- **Repeat one** replays the current track. **Autoplay** (`profiles.settings.autoplay`, default `false`) only acts after `ended`, and draws only from the user's own ready tracks (F2).
- **Active device.** `playback_state.device_id` is the active device. It alone writes the playback fields (context, cursor, current track and item, position and `position_at`, `is_playing`, shuffle, repeat, `ended`) with `PUT /playback-state`. Another device's PUT gets `409 not_active_device` with the current state, unless it sends `takeOver: true`. Only an explicit user action on that device sends `takeOver` (pressing play, next, seek, shuffle or repeat there, or "Play here"); `device_id` then moves to it. Remote control of another device is the Connect could-have, not v1.
- **Non-active and detached devices.** A device that isn't playing adopts the server state when the app opens or gains focus, starting paused at `position_ms`, and shows "Playing on {device}" while another device is active. If the active device's own non-user write (a heartbeat or an auto-advance) gets `409 not_active_device`, it never changes its own playback: it keeps playing, stops writing, and the player shows "Not synced. Tap to take over". Its next explicit action sends `takeOver: true`.
- **Write cadence.** Web: on play, pause, seek, track change and toggles, plus every 30 s while playing. Mobile: on the same events, plus every 60 s while the app is in the foreground; no periodic writes from a backgrounded phone (a locked phone writes on track change and pause only). Offline writes are dropped; the latest state is sent on reconnect.
- **Validation.** PUT checks in one query that `contextId`, `currentTrackId`, `currentItemId` and every id in `contextTrackIds` belong to the caller; queue ops check `trackId`. Anything else is `400 validation_failed`.

---

## API

### Conventions

- **Base** `/api/v1`, JSON, validated with the zod schema from `packages/contract` (both ways in tests). Ids are UUIDs.
- **Auth.** A request that carries `Authorization: Bearer <access token>` is authenticated by that token alone, and cookies are ignored. Otherwise the web session cookie (`@supabase/ssr`) is used. The server calls `supabase.auth.getClaims()`, then, in the request transaction, loads the profile together with the device whose `auth_session_id` equals the JWT `session_id`. A revoked device answers `401 device_revoked`. Only `status = 'active'` passes, except for the invite-acceptance routes, which also accept `invited`. Cookie-authenticated `POST/PUT/PATCH/DELETE` requests must send `Content-Type: application/json` and an `Origin` equal to `APP_ORIGIN` (CSRF guard). `/api/v1` sends no `Access-Control-Allow-*` headers (the mobile app isn't subject to CORS).
- **Who:** `public`, `invited` (an invite session that hasn't accepted yet), `member` (any active user, own data only), `admin` (role `admin`), `cron` (`Authorization: Bearer $CRON_SECRET`).
- **Ownership.** Another user's resource answers `404 not_found`, never 403, so nothing leaks its existence. No route ever accepts a storage key from a client: the server builds every key from ids it owns.
- **Errors.** `{ "error": { "code": string, "message": string, "details"?: unknown } }`. Codes: `unauthorized` 401, `device_revoked` 401, `reauth_required` 401, `forbidden` 403, `not_found` 404, `validation_failed` 400, `conflict` 409, `version_conflict` 409, `not_active_device` 409, `device_conflict` 409, `duplicates` 409, `storage_full` 409, `in_progress` 409, `not_ready` 409, `unsupported_format` 415, `file_too_large` 413, `integrity_failed` 422, `gone` 410, `rate_limited` 429, `internal` 500. Messages are plain sentences in the brand voice. The UI copy comes from `brand.md`.
- **Lists** use cursor pagination: `?cursor=&limit=` (default 50, max 200), with the response `{ items, nextCursor }`. The cursor is an opaque base64 of the keyset row (sort values, then id), compared as a row.
- **Request caps.** Batch upload ≤ 500 files. `stream-urls` ≤ 50 ids. `covers/urls` ≤ 200 ids. Playlist add ≤ 500 tracks. Play events ≤ 500 per post. Sync pages ≤ 1000 rows. Search `q` ≤ 200 characters and ≤ 8 words. Bodies stay well under Vercel's 4.5 MB limit, because audio and images never go through the API.
- **Rate limits.** A fixed-window limiter in Postgres (`rate_limit_hit(key, window, max)`, one upsert per limited request) answers `429 rate_limited`. Starting limits, per user unless noted: `/uploads/batch` 60/min, `/uploads/:id/complete` 240/min, `/tracks/:id/reprocess` 30/h, `/covers/uploads` 60/h, `/export/*` 10/h, `/search` 120/min, `/tracks/stream-urls` 120/min, `/admin/invites` 20/h, `POST /auth/confirm` 10/min per IP.
- **Security headers (app routes).** `middleware.ts` sets, for every app page, `/auth/*` and `/api/*`: `Content-Security-Policy: default-src 'self'; script-src 'self' 'nonce-{n}' 'wasm-unsafe-eval'; worker-src 'self' blob:; img-src 'self' blob: data: https://{b2-s3-host}; media-src 'self' blob: https://{b2-s3-host}; connect-src 'self' https://{project}.supabase.co https://{b2-s3-host}; frame-ancestors 'none'; base-uri 'none'; form-action 'self'`, plus `X-Content-Type-Options: nosniff`, `Referrer-Policy: no-referrer` and `Strict-Transport-Security`. A nonce makes a page dynamic, so the static landing page gets the same headers with `script-src 'self' 'unsafe-inline'` instead (it has no user data and no user-generated content).

### Auth settings

Checked in as `supabase/config.toml` (local stack) and applied by hand to both cloud projects. The deploy checklist compares the production project with this list.

| setting | value |
| --- | --- |
| `enable_signup` | `false` |
| `enable_anonymous_sign_ins` | `false` |
| external providers | all off |
| `minimum_password_length` | `10` |
| email OTP expiry (`otp_expiry`) | `86400` s (the maximum; invite and recovery links are shared by chat). `expiresAt` in API responses is computed from it. |
| `site_url` | `APP_ORIGIN` |
| `additional_redirect_urls` | `[]` |
| refresh token rotation | on |
| `jwt_expiry` | `3600` s (bounds how long a revoked session's last token lives where the device check doesn't reach) |
| JWT signing keys | asymmetric (for `getClaims`) |

### Contract shapes (zod in `packages/contract`; summarised)

```ts
type TrackDto = {
  id: string; status: 'processing' | 'ready' | 'failed' | 'disabled';
  title: string; artistName: string | null; albumTitle: string | null; albumArtistName: string | null;
  albumId: string | null; artistId: string | null; trackNo: number; discNo: number; // 0 = unknown
  year: number | null; genre: string | null; durationMs: number | null; codec: string | null;
  lossless: boolean | null; sampleRateHz: number | null; bitDepth: number | null;
  sizeBytes: number; ext: string; mime: string; contentMd5: string;
  coverId: string | null; coverUrl300: string | null;            // online routes only; day-bucketed signed URL
  isFavorite: boolean; playCount: number; lastPlayedAt: string | null;
  addedAt: string; updatedAt: string; statusReason: string | null;
};

// The offline mirror stores no URLs: covers resolve through GET /covers/urls online
// and through local files offline.
type SyncTrackDto = Omit<TrackDto, 'status' | 'coverUrl300' | 'isFavorite'> & {
  status: TrackDto['status'] | 'deleted';
  sortTitle: string; sortArtist: string; sortAlbum: string;   // stored as-is on the device
};

type UploadBatchRequest = {
  batchId: string; client: 'web' | 'ios' | 'android';
  files: Array<{ clientFileId: string; kind: 'audio' | 'cover'; name: string;
                 relativePath?: string; size: number; md5: string /* hex */; mime?: string }>; // ≤ 500; cover ≤ 10 MiB
};
type UploadBatchResult = {
  results: Array<
    | { clientFileId: string; outcome: 'upload' | 'resume'; sessionId: string;
        mode: 'single' | 'multipart'; partSize?: number; partCount?: number; expiresAt: string }
    | { clientFileId: string; outcome: 'duplicate'; trackId: string }
    | { clientFileId: string; outcome: 'storage_full' }
    | { clientFileId: string; outcome: 'unsupported'; reason: 'extension' | 'too_large' | 'empty' }>;
  usage: { usedBytes: number; reservedBytes: number; limitBytes: number };
};

type ContextCursor = { v: Array<string | number>; id: string };
type PlaybackStateDto = {
  version: number; deviceId: string | null; deviceName: string | null;
  context: { type: 'album' | 'artist' | 'playlist' | 'favorites' | 'library' | 'search' | 'queue';
             id: string | null; sort?: string; trackIds?: string[] } | null;
  contextCursor: ContextCursor | null; currentTrackId: string | null; currentItemId: string | null;
  positionMs: number; positionAt: string | null; isPlaying: boolean;
  userQueue: Array<{ entryId: string; trackId: string }>;          // ≤ 1000
  shuffle: { on: boolean; seed: string | null; cycle: number; lastKey: string | null };
  repeat: 'off' | 'all' | 'one'; ended: boolean; updatedAt: string;
};
type PlaybackStatePut = Pick<PlaybackStateDto,
  'context' | 'contextCursor' | 'currentTrackId' | 'currentItemId' | 'positionMs' |
  'isPlaying' | 'shuffle' | 'repeat' | 'ended'> & {
  deviceId: string; takeOver: boolean; consumedEntryIds?: string[];
};
type QueueOp =
  | { op: 'playNext' | 'enqueue'; entryId: string; trackId: string }
  | { op: 'remove'; entryId: string }
  | { op: 'move'; entryId: string; afterEntryId: string | null }
  | { op: 'clear' };

type PlayEventIn = {
  id: string; trackId: string; deviceId: string | null; playedAt: string; msPlayed: number;
  contextType?: 'album' | 'artist' | 'playlist' | 'favorites' | 'library' | 'search' | 'queue';
  contextId?: string; clientTz: string;
  trackTitle: string; artistName?: string | null; albumTitle?: string | null;   // snapshot from the device mirror
};
type PlayEventsResult = { results: Array<{ id: string; outcome: 'accepted' | 'duplicate' | 'orphaned' }> };

// Cursor (opaque base64 JSON): { v: 1, since, runStart, entity, ts, id }.
// Walk order: tombstones, artists, albums, tracks, playlists, playlistItems, favorites.
type SyncPage = {
  cursor: string; hasMore: boolean; fullResync: boolean;
  tombstones: Array<{ entity: 'track' | 'album' | 'artist' | 'playlist' | 'playlist_item' | 'favorite';
                      entityId: string; at: string }>;
  artists: ArtistDto[]; albums: AlbumDto[]; tracks: SyncTrackDto[]; playlists: PlaylistDto[];
  playlistItems: Array<{ id: string; playlistId: string; trackId: string; sortKey: string; addedAt: string }>;
  favorites: Array<{ trackId: string; createdAt: string }>;
};

type ManifestItem = { trackId: string; sizeBytes: number; md5: string; ext: string; mime: string;
                      url: string; urlExpiresAt: string; coverId: string | null; coverUrl600: string | null };
```

**Sync rules (client and server).**
- A sync run starts from the cursor the previous run ended with. The server sets `since = previous runStart − 120 s` (the epoch on a first sync) and `runStart = clock_timestamp()`. Each entity is read with the keyset query above from `(since, nil uuid)`, filling up to 1000 rows per page, and the cursor carries the exact position, so pages never overlap and a tied bulk write pages through. The 120 s overlap applies only at the start of a run, and covers every commit delay because transactions are bounded (see "Transactions and time").
- `fullResync` when the previous `runStart` is older than tombstone retention (180 days): the device clears its mirror and syncs from the epoch.
- The device applies tombstones before rows, and applies the cascades the server doesn't write: a track tombstone drops its playlist items, its favorite and its local file (and scope links); a playlist tombstone drops its items. A track row with status `deleted` or `disabled` removes the local file. Upserts are idempotent.
- `devices.last_sync_at` of the session's device is stamped. A revoked device gets `401 device_revoked` here like everywhere, which is the device's signal to wipe.

### Routes by flow

**66 route handlers**: 63 under `/api/v1`, plus `/api/cron/sweep` and `GET` and `POST /auth/confirm`. Pages (the landing page and app screens) aren't counted.

#### F01: upload (S18) and ingest

| method path | does | who | input | output | flow |
| --- | --- | --- | --- | --- | --- |
| POST `/api/v1/uploads/batch` | Per file, in order: rejects bad extensions (whitelist per kind) and sizes; finds duplicates (an existing track with the same MD5 → `duplicate`) and live sessions (→ `resume`); otherwise, under the profile row lock, creates a session that reserves its size (→ `upload`), or answers `storage_full`. Cover sidecars (`kind: 'cover'`, ≤ 10 MiB, jpg/png/webp) reserve bytes like audio. | member | `UploadBatchRequest` | `UploadBatchResult` | F01, F6 |
| GET `/api/v1/uploads/:id` | Session status. For `single`: a fresh presigned PUT URL (TTL 1 h; Content-Length, Content-Type and Content-MD5 fixed in the signature). For `multipart`: the parts uploaded so far (ListParts), for resume. Moves `expires_at` to `least(now() + 72 h, created_at + 7 days)`. | member | — | `{ session, upload?: { url, headers, expiresAt }, uploadedParts?: [{ partNumber, size }] }` | F01 |
| POST `/api/v1/uploads/:id/parts` | Creates the S3 multipart upload on the first call (session row locked), then signs PUT URLs for the requested parts (≤ 100 per call) with `ContentLength` = part size (the remainder for the last part) and `ContentMD5`, and stores their MD5s | member | `{ parts: [{ partNumber, md5 }] }` | `{ parts: [{ partNumber, url, headers }], expiresAt }` | F01 |
| POST `/api/v1/uploads/:id/complete` | Idempotent. Guard `pending → completing` in its own short transaction (an already completed session returns its track; one that is `completing` returns `409 in_progress`). Then, outside any transaction: multipart → server-side ListParts (exactly `part_count` parts, each `part_size` except a shorter last one, ETags equal to `part_md5s`; client ETags are never used) and CompleteMultipartUpload; HeadObject size equals the declared size; `file-type` over the range tokenizer must give the family the extension claims. Then one transaction: audio → inserts the `tracks` row (`processing`, `mime` from the sniff) and enqueues `extract` (deduplicated); cover → enqueues `apply_sidecar_cover` for sidecars; session → `completed` (the triggers move the bytes). `after()` runs the job. Integrity failure: deletes the object, session `failed`, `422 integrity_failed`. Wrong real type: same, `415`. A track with the same MD5 that appeared meanwhile: deletes the object, session `failed` (`duplicate`), `409 duplicates` with `details: { trackId }`. | member | — | `{ track: TrackDto }` or `{ coverUploadId }` | F01, F6 |
| DELETE `/api/v1/uploads/:id` | Aborts: AbortMultipartUpload or deletes the partial object (outside the transaction), status `aborted` (the trigger releases the bytes once) | member | — | 204 | F01 |
| GET `/api/v1/uploads` | Sessions for S18 progress across reloads and devices | member | `?batchId=&status=&cursor=` | `Page<UploadSessionDto>` | F01 |
| POST `/api/v1/tracks/:id/reprocess` | Re-runs extraction for a `failed` track, or re-reads tags while keeping the fields the user edited | member | — | `{ track }` | F01 |

#### F01 / F02: library (S05, S07, S10, S11, S19)

| method path | does | who | input | output | flow |
| --- | --- | --- | --- | --- | --- |
| GET `/api/v1/library/tracks` | Tracks list (ready and processing; failed on request), keyset on the sort columns | member | `?sort=added\|title\|artist\|album&dir=&status=&q=&cursor=&limit=` | `Page<TrackDto>` | F01, F02 |
| GET `/api/v1/library/albums` | Albums with cover, artist, year and track count | member | `?sort=added\|title\|artist\|year&q=&cursor=` | `Page<AlbumDto>` | F01 |
| GET `/api/v1/library/artists` | Artists (by `sort_name`) with album and track counts | member | `?q=&cursor=` | `Page<ArtistDto>` | F01 |
| GET `/api/v1/tracks/:id` | One track | member | — | `TrackDto` | F02 |
| PATCH `/api/v1/tracks/:id` | Edits tags (S19) under the library lock: re-groups the album and artist, recomputes sort keys, records `user_edited_fields`. The file is untouched. | member | `{ title?, artistName?, albumTitle?, albumArtistName?, trackNo?, discNo?, year?, genre?, coverUploadId? \| removeCover? }` | `TrackDto` | F01 |
| DELETE `/api/v1/tracks/:id` | Soft delete (`deleted`), then a `purge_track` job after `PURGE_GRACE_MINUTES`. The bytes come back at purge. | member | — | 204 | F01 |
| POST `/api/v1/tracks/bulk-delete` | Same for ≤ 500 ids | member | `{ ids: string[] }` | `{ deleted: number }` | F01 |
| GET `/api/v1/albums/:id` | Album header and tracks (disc, track number) | member | — | `{ album, tracks: TrackDto[] }` | F01, F02 |
| PATCH `/api/v1/albums/:id` | Bulk tag edit for every track of the album (title, artist, year, cover), under the library lock | member | `{ title?, artistName?, year?, coverUploadId? }` | `{ album }` | F01 |
| GET `/api/v1/artists/:id` | Artist: albums, most-played tracks (personal counts), loose tracks | member | — | `{ artist, albums, topTracks, otherTracks }` | F02 |
| GET `/api/v1/home` | S05: quick picks (6–8 recent contexts), recently played, recently added albums. Later: most played, not played in a while. Empty library: `{ empty: true }`. | member | `?tz=` | `{ quickPicks, shelves: [...] }` | F02 |
| POST `/api/v1/covers/uploads` | Creates a `kind: 'cover'` upload session (≤ 10 MiB, JPEG/PNG/WebP; reserves its bytes; `batch_id` = its own id) and returns a presigned PUT. The client PUTs, calls `/uploads/:id/complete`, then PATCHes a track, album or playlist with `coverUploadId`. The PATCH resolves it with `owner_id = caller, kind = 'cover', status = 'completed'` (404 otherwise), builds the WebP covers, deletes the inbox object and marks the session `consumed`. | member | `{ size, mime, md5 }` | `{ coverUploadId, url, headers, expiresAt }` | F01, F03 |
| GET `/api/v1/covers/urls` | Day-bucketed signed URLs for covers the caller owns (the mobile mirror stores only `coverId`) | member | `?ids=` (≤ 200) | `{ urls: [{ coverId, url300, url600, expiresAt }] }` | F02, F07 |

#### F02 / F04: streaming, queue and playback state (S12, S13, S14)

| method path | does | who | input | output | flow |
| --- | --- | --- | --- | --- | --- |
| GET `/api/v1/tracks/stream-urls` | Presigned GETs (TTL 2 h, `response-content-type` set) for ready tracks the user owns. Range requests go straight to B2. | member | `?ids=a,b,c` (≤ 50) | `{ urls: [{ trackId, url, expiresAt, mime, sizeBytes }], errors: [{ trackId, code: 'not_found'\|'not_ready'\|'unavailable' }] }` | F02 |
| GET `/api/v1/playback-state` | The user's playback state (creates it at version 1 if absent), with the active device's name | member | — | `PlaybackStateDto` | F02, F04 |
| PUT `/api/v1/playback-state` | Writes the playback fields if the caller's device is the active one (or there is none, or `takeOver: true`), removes `consumedEntryIds` from the queue, `version + 1`. Ids are checked against the caller. | member | `PlaybackStatePut` | `PlaybackStateDto` or `409 not_active_device` + current state | F02, F04 |
| POST `/api/v1/playback-state/queue` | One queue op from any device, applied in one `UPDATE` (`version + 1`); the queue stays ≤ 1000 entries | member | `QueueOp` | `PlaybackStateDto` | F02, F04 |
| GET `/api/v1/contexts/:type/:id/tracks` | Ordered members of a context: natural order after a cursor (keys in the Members table), or shuffle order after `lastKey` for a seed (SQL). `id` = `all` for the library and favorites. | member | `?order=natural\|shuffle&sort=&after=<base64 ContextCursor>&seed=&lastKey=&limit=` (≤ 200) | `{ members: [{ key: ContextCursor \| string, trackId, itemId? }], end: boolean }` | F02, F04 |
| POST `/api/v1/play-events` | Idempotent set-based insert (see Key queries). Unknown or purged tracks are stored with the client's snapshot and `track_id` NULL (`orphaned`); unknown devices with `device_id` NULL; `played_at` clamped to now; `counted` computed on the server. For newly inserted counted events with a track, in the same transaction: `play_count + 1` and `last_played_at`. The outbox removes every event that comes back with any outcome. | member | `{ events: PlayEventIn[] }` (≤ 500) | `PlayEventsResult` | F02, F8 |
| GET `/api/v1/history` | History (should): play events newest first, shown in the event's own zone | member | `?from=&to=&cursor=` | `Page<PlayEventDto>` | F8 |

#### F03: playlists (S09, S16, S17); F05: favorites (S08)

| method path | does | who | input | output | flow |
| --- | --- | --- | --- | --- | --- |
| GET `/api/v1/playlists` | The user's playlists with counts, durations and mosaic covers | member | `?q=&cursor=` | `Page<PlaylistDto>` | F03 |
| POST `/api/v1/playlists` | Creates one (manual, or smart with rules). Rules: a zod discriminated union over fixed fields (`genre`, `year`, `added_at`, `play_count`, `last_played_at`) and operators (`eq`, `neq`, `gte`, `lte`, `between`, `contains`), ≤ 20 conditions, depth ≤ 2, compiled only to parameterised Drizzle conditions (never `sql.raw`). | member | `{ name, description?, kind?, rules? }` | `PlaylistDto` | F03 |
| GET `/api/v1/playlists/:id` | Header: name, description, cover or mosaic, count, duration | member | — | `PlaylistDto` | F03 |
| PATCH `/api/v1/playlists/:id` | Rename, describe, set or remove the cover, edit rules | member | `{ name?, description?, coverUploadId? \| removeCover?, rules? }` | `PlaylistDto` | F03 |
| DELETE `/api/v1/playlists/:id` | Deletes it, with a tombstone | member | — | 204 | F03 |
| GET `/api/v1/playlists/:id/items` | Items in `sort_key` order (smart: computed from the rules). `q` searches inside the playlist (F8). | member | `?q=&cursor=&limit=` | `Page<{ itemId, sortKey, addedAt, track: TrackDto }>` | F03 |
| POST `/api/v1/playlists/:id/items` | Locks the playlist row (`for update`), then adds tracks after an item (or at the end). Keys are generated on the server; if one would pass 64 characters, the same transaction rebalances the playlist (deferred unique constraint). `onDuplicate: 'ask'` returns `409 duplicates` with the ids already present; `'skip'` or `'add'` resolves it. | member | `{ trackIds (≤ 500), afterItemId?: string \| null, onDuplicate?: 'ask'\|'skip'\|'add' }` | `{ items }` | F03 |
| PATCH `/api/v1/playlists/:id/items/:itemId` | Moves one item under the same playlist row lock: reads the neighbours' keys and writes one new `sort_key` (rebalancing past 64 characters) | member | `{ afterItemId: string \| null }` | `{ itemId, sortKey }` | F03 |
| POST `/api/v1/playlists/:id/items/remove` | Removes items, with tombstones | member | `{ itemIds }` | `{ removed }` | F03 |
| POST `/api/v1/playlists/import` | M3U/M3U8 import (should): matches each line by `relative_path`, then filename, then title and artist, within the user's library | member | `{ name, content }` (text ≤ 1 MB) | `{ playlistId, matched, unmatched: string[] }` | F6 |
| GET `/api/v1/favorites` | Favorited tracks, newest first | member | `?cursor=` | `Page<TrackDto>` | F05 |
| PUT `/api/v1/favorites/:trackId` | Favorite (idempotent); deletes that track's `favorite` tombstone in the same transaction | member | — | 204 | F05 |
| DELETE `/api/v1/favorites/:trackId` | Unfavorite (idempotent; writes a tombstone; the undo toast calls PUT) | member | — | 204 | F05 |

#### F06: search (S06)

| method path | does | who | input | output | flow |
| --- | --- | --- | --- | --- | --- |
| GET `/api/v1/search` | Normalises the query (`search_norm`) and splits it into words. Each word has `\`, `%` and `_` escaped and must appear (`search_text like $w escape '\'`, served by the trigram index). Ranking: title or name prefix > word start > substring > trigram similarity. Returns the top result plus the groups. One- and two-character queries use prefix matching only. | member | `?q=` (≤ 200 chars, ≤ 8 words) `&types=tracks,albums,artists,playlists&limit=` (≤ 50 per type) | `{ top, tracks, albums, artists, playlists }` | F06 |

#### F07 / F5: offline downloads (S24, mobile)

| method path | does | who | input | output | flow |
| --- | --- | --- | --- | --- | --- |
| GET `/api/v1/downloads/manifest` | The files for one scope, with signed URLs (6 h) and 600 px cover URLs. Ready tracks only. The device sums `sizeBytes` over every page before it starts. | member | `?scope=track\|album\|playlist\|favorites\|library&id=&cursor=&limit=` (≤ 500) | `Page<ManifestItem>` | F07 |
| PUT `/api/v1/devices/:id/downloads` | Registers copies the device has verified (size + MD5) | member | `{ items: [{ trackId, sizeBytes }] }` | `{ registered }` | F07 |
| POST `/api/v1/devices/:id/downloads/remove` | Unregisters copies the device removed | member | `{ trackIds }` | `{ removed }` | F07 |
| GET `/api/v1/sync` | Offline mirror feed (see "Sync rules"). The device comes from the session. | member | `?cursor=` | `SyncPage` | F07, F5 |

#### F10 + admin: invites, limits, account (admin page, S03, S04, S21, S22)

| method path | does | who | input | output | flow |
| --- | --- | --- | --- | --- | --- |
| GET `/auth/confirm` | No side effects (chat apps fetch links to build previews). Renders a minimal page (`noindex`, `Referrer-Policy: no-referrer`) with a "Continue" button that POSTs `token_hash` and `type` | public | `?token_hash=&type=invite\|recovery` | HTML | F10 |
| POST `/auth/confirm` | Checks `Origin`, validates `type ∈ {invite, recovery}`, calls `verifyOtp({ token_hash, type })`, sets the session cookie, redirects: a profile still `invited` → `/welcome` (whatever the link type); `recovery` → `/reset`; expired → `/login?link=expired`. 10/min per IP. | public | form `token_hash`, `type` | 303 | F10 |
| POST `/api/v1/admin/invites` | `auth.admin.generateLink({ type: 'invite', email })`, which creates the auth user. Inserts the profile (`invited`, with its limit) and the invite. Builds our own link `APP_ORIGIN/auth/confirm?token_hash=…&type=invite`. `expiresAt` from the OTP expiry setting (24 h). | admin | `{ email, storageLimitBytes }` | `{ inviteId, userId, link, expiresAt }` | F10 |
| POST `/api/v1/admin/invites/:id/link` | A new link for an unaccepted invite: type `recovery` when the auth user's `email_confirmed_at` is set (GoTrue refuses an invite link for a confirmed user), `invite` otherwise | admin | — | `{ link, expiresAt }` | F10 |
| DELETE `/api/v1/admin/invites/:id` | Revokes an unaccepted invite: under a row lock, only while `invites.status = 'pending'` (409 otherwise), deletes the profile, then the auth user | admin | — | 204 | F10 |
| GET `/api/v1/admin/users` | Usage only: email, name, status, limit, used, reserved, track count, last seen. **Never** anyone's library (privacy among friends). | admin | `?cursor=` | `Page<AdminUserDto>` | — |
| PATCH `/api/v1/admin/users/:id` | Takes the profile row lock first. Sets the storage limit, or moves status `active ↔ disabled` only (disable = `auth.admin.updateUserById(id, { ban_duration: '876000h' })`, enable = `'none'`); the one exception is `deleting → active`, which cancels a pending account deletion during its grace period. Never the caller's own id. | admin | `{ storageLimitBytes?, status?: 'active'\|'disabled' }` | `AdminUserDto` | — |
| POST `/api/v1/admin/users/:id/recovery-link` | Password reset by admin link until a domain and SMTP exist | admin | — | `{ link, expiresAt }` | F10 |
| GET `/api/v1/me` | Profile, usage (`used`, `reserved`, `limit`), settings | invited, member | — | `MeDto` | — |
| PATCH `/api/v1/me` | Display name, settings (`autoplay`) | member | `{ displayName?, settings? }` | `MeDto` | F12 |
| POST `/api/v1/me/activate` | After `/welcome` sets the password (`supabase.auth.updateUser`): `invited → active`, `invites.accepted_at` | invited | — | `MeDto` | F10 |
| DELETE `/api/v1/me` | Account deletion. Needs a recent password sign-in: the JWT `amr` entry for `password` must be under 5 minutes old (`401 reauth_required` otherwise; `iat` alone isn't enough because refreshes renew it). Sets `status = 'deleting'`, signs out everywhere, enqueues `purge_user` with `run_after` per OPEN 12 (proposed: now + 7 days) | member | `{ confirm: 'DELETE' }` | 202 | — |
| PUT `/api/v1/devices/:id` | Registers or updates this device and links it to the JWT `session_id`: `insert … on conflict (id) do update … where devices.owner_id = excluded.owner_id`. An id that belongs to someone else, or a session already linked to another device, answers `409 device_conflict` and the client makes a new id | member | `{ name, platform, appVersion?, allowCellularDownloads? }` | `DeviceDto` | F07 |
| GET `/api/v1/devices` | Devices with download count and bytes | member | — | `DeviceDto[]` | F07 |
| DELETE `/api/v1/devices/:id` | Remote sign-out: `revoked_at`, deletes its `downloads` rows; from then on its session gets `401 device_revoked` on every route, and the device wipes its downloads on that answer. Also ends the Supabase session (delete the `auth.sessions` row by id over the owner connection, if Supabase grants that: verify in 1b; otherwise the settings page offers "Sign out all other devices", `auth.signOut({ scope: 'others' })`). | member | — | 204 | F07 |

#### F7: export (S21 / account page)

Every export reads in keyset pages of 1000 rows, each in its own short transaction, and writes to the response between pages (never inside a transaction). CSV writers (`packages/media`) quote every field per RFC 4180 and prefix any cell that starts with `=`, `+`, `-`, `@`, tab or carriage return with `'`. Zip entry names and M3U8 path segments replace `[^\p{L}\p{N} ._()-]` with `_`, strip leading dots, cap at 120 characters and de-duplicate with ` (2)`. Both have unit tests.

| method path | does | who | input | output | flow |
| --- | --- | --- | --- | --- | --- |
| GET `/api/v1/export/playlists.zip` | Every playlist as `.m3u8` (paths `Artist/Album/NN Title.ext`, matching the later audio export) or `.csv`, streamed with `client-zip` | member | `?format=m3u8\|csv` | `application/zip` | F7 |
| GET `/api/v1/export/playlists/:id` | One playlist | member | `?format=m3u8\|csv` | file | F7 |
| GET `/api/v1/export/history.csv` | Play history: UTC time, local time in `client_tz`, title, artist, album, ms played, context | member | `?from=&to=` | `text/csv` (streamed) | F7, F8 |
| GET `/api/v1/export/library.csv` | Every track with tags, size, MD5 and added date | member | — | `text/csv` (streamed) | F7 |

#### Infrastructure

| method path | does | who | input | output | flow |
| --- | --- | --- | --- | --- | --- |
| GET `/api/v1/health` | Liveness for deploy checks (no database call) | public | — | `{ ok, version }` | — |
| GET\|POST `/api/cron/sweep` | Runs the sweep (see Jobs) within a 250 s budget | cron | — | `{ ran: {...} }` | — |

**Webhooks in:** none. There is no payments provider, and uploads are confirmed by the client calling `/complete`, not by storage events. **Webhooks out:** none.

### Jobs

All jobs run on the owner connection, open each transaction with `set local statement_timeout = '60s'` and `set local idle_in_transaction_session_timeout = '30s'`, and do network I/O only between transactions.

| job | schedule or trigger | what it does |
| --- | --- | --- |
| `extract` | Enqueued by `/complete`; run by `after()` straight away; retried by the sweep (backoff 1 min, 10 min, 1 h, 6 h; 5 attempts for storage or network errors, 2 for parser errors and timeouts) | Multipart uploads first stream the object and compare its full MD5 with the client's (so does a single PUT whose ETag isn't the MD5). Then `music-metadata` `parseFromTokenizer` over `@tokenizer/s3` with `skipCovers: true`, wrapped in a 120 s timeout; the embedded picture is read only if it declares ≤ 10 MB. No audio stream or duration → `failed`. Effective tags with fallbacks (path, then filename), truncated to 300 characters; `tags_raw` from the allow-list; sort keys. Embedded cover → sha256 → `sharp(input, { limitInputPixels: 40_000_000, failOn: 'error' })` to WebP 600 and 300 uploaded under a fresh cover id → under the library lock: cover row (reuse on a hash conflict), artist and album upsert, track `ready`. When the last attempt fails, the same transaction sets the track `failed` with `status_reason = 'extract_gave_up: …'` (S18 offers "Try again"). |
| `apply_sidecar_cover` | `/complete` of a sidecar `cover` session | Under the library lock: for tracks of the same batch and folder that have no embedded art, sets their album's cover if empty. Order-independent: runs whether the audio or the image arrived first. Deletes the inbox object whether it succeeds or fails, and marks the session `consumed`. |
| `regroup_batch` | When a batch has no live sessions left (or 10 min after its last activity) | Under the library lock: merges albums that the same folder split by track artist when `albumartist` was missing: one album, artist "Various Artists" if the artists differ. |
| `purge_track` | `DELETE /tracks/:id`, `run_after = now() + PURGE_GRACE_MINUTES` | Deletes every version of the object (B2 keeps versions). Then in one transaction: deletes the row (cascades; the trigger gives the bytes back) and writes a `track` tombstone. Then enqueues `library_cleanup`. |
| `purge_user` | `DELETE /me` (after the grace period of OPEN 12) or the admin's removal | Deletes every object under `u/{id}/`, then the profile (cascade), then the auth user. |
| `library_cleanup` | After purges and tag edits; hourly from the sweep | Under the library lock: deletes albums with no tracks, then artists with no albums and no tracks, then unreferenced covers, writing tombstones. After commit: deletes those covers' objects. |
| **sweep** (route) | GitHub Actions **hourly**; Vercel cron daily as a second trigger | 1) Requeues `running` jobs locked for more than 10 min. 2) Runs due jobs within the budget. 3) Expires sessions past `expires_at` and cover sessions left `completed` for more than 24 h: aborts multipart uploads, runs HeadObject and deletes the key whatever the status, then `expired` (the trigger releases the bytes). 4) Resets `completing` sessions untouched for more than 10 min back to `pending`. 5) Checks the storage counters per user (Key queries) and logs any drift it corrects. 6) Prunes tombstones older than 180 days, finished jobs older than 30 days, finished upload sessions older than 30 days (never a cover still `completed`), and `rate_limits` rows older than a day. 7) Once a day, deletes `u/{uid}/in/` objects older than 7 days that no live session claims. Its database query also keeps Supabase Free from pausing. |
| **db backup** (workflow) | GitHub Actions nightly 03:00 UTC, Environment `production` | Through the **session pooler** (the direct host is IPv6-only): `pg_dump -Fc -n public \| age -r "$BACKUP_AGE_RECIPIENT" > public.dump.age` and `pg_dump --data-only -t auth.users -t auth.identities \| age -r … > auth.sql.age`, uploaded to a separate B2 `tunehold-backups` bucket with SSE-B2 default encryption and a lifecycle rule keeping 30 days. Restore drill once per milestone into a fresh Supabase project (or `supabase start`): create the `tunehold_app` role (the role block of `schema.sql`), `age -d -i key.txt auth.sql.age \| psql …` (auth first; whether the target accepts inserts into `auth.*` is checked in the first drill), then `age -d -i key.txt public.dump.age \| pg_restore --no-owner -d …`. Audio isn't backed up: B2 is the primary copy, and users keep their originals (landing FAQ). |
| B2 lifecycle rules | Set once with the `b2` CLI | Audio bucket: "keep only the last version" (so deletes free space) and cancel unfinished large files after 7 days (a backstop for the sweep). |

---

## Audio pipeline (summary)

1. **Pick.**
   - Web: files, or a folder dropped or picked (`webkitGetAsEntry`; on Chromium, `showDirectoryPicker` with its handle in IndexedDB).
   - Mobile: `File.pickFileAsync({ multiple })` (iOS copies picked files into the app's storage, so a pick is capped at about 2 GB per batch and each copy is deleted after its `/complete`) or `Directory.pickDirectoryAsync()` (no copy). Big imports go through the web app.
   - Accepted: `mp3`, `m4a`/`mp4`/`aac`, `flac`, `wav`, plus `cover.jpg`, `folder.jpg` and `front.jpg|png` sidecars (≤ 10 MiB).
2. **Fingerprint.** An MD5 per file: `hash-wasm` in a Web Worker on the web, `file.info({ md5: true })` on mobile. It is used only for duplicates inside the user's own library.
3. **Reserve.** `POST /uploads/batch` in chunks of ≤ 500, in walk order. It returns `upload`, `resume`, `duplicate`, `storage_full` or `unsupported` per file. "{done} of {total} added before your space filled up" falls out of the order.
4. **Transfer straight to B2.**
   - Web: Uppy runs 4 files in parallel. Under 32 MB: a single PUT whose URL is fetched just before it starts (`GET /uploads/:id`). From 32 MB: multipart, 16 MB parts signed in batches.
   - Mobile: a single PUT per file from the transfer queue (at most 3 in flight).
   - Every PUT and part carries the signed `Content-Length`, `Content-Type` and `Content-MD5` (base64 of the MD5). A body of another length gets 403 from B2 (a gate in slice 1a).
5. **Complete.** `POST /uploads/:id/complete` checks the parts on the server (ListParts), the size, and the real type over the range tokenizer. In one transaction it inserts the track and settles the bytes (triggers), then enqueues extraction.
6. **Extract.** See the `extract` job. Covers are deduplicated per user by image hash and stored under their row id; grouping and sort keys come from `packages/media`.
7. **Store.**
   - `u/{userId}/o/{trackId}.{ext}` is written once and never rewritten (F6).
   - Covers live at `u/{userId}/c/{coverId}-{600|300}.webp`.
   - Inbox images live at `u/{userId}/in/{sessionId}.{ext}` until they are used or expire.
   - Later streaming copies would go to `u/{userId}/s/{trackId}.m4a`.
   - There is no cross-user deduplication: two users uploading the same file get two objects.

---

## The parts that bite

- **Resumable uploads.**
  - The browser can't keep `File` objects across a reload, so resuming means re-dropping the folder: duplicates come back as `duplicate`, and half-done multipart uploads come back as `resume` with their uploaded parts. On Chromium, the stored directory handle avoids re-picking.
  - Mobile uploads resume from the saved transfer queue (see "Mobile transfers"). Whether picked folders stay readable after an app restart is **to verify on device**; if not, the user re-picks and the duplicates are skipped.
  - Stale sessions expire after 72 h of inactivity, and never live past 7 days; expiry deletes the object and releases the bytes. B2's unfinished-large-file rule is the backstop.
  - The first import of ~343 GB takes about 38 h at 20 Mbps upstream (estimate), so resume matters more than speed. It belongs on the web app.
- **S3 compatibility.**
  - AWS SDK v3 sends CRC32 checksum headers by default since v3.729, and B2 rejects them. `packages/storage` sets `requestChecksumCalculation: 'WHEN_REQUIRED'` and `responseChecksumValidation: 'WHEN_REQUIRED'`, and strips `x-amz-checksum-mode` on GETs if B2 still rejects it.
  - Presigned PUTs and parts: `getSignedUrl(s3, new PutObjectCommand({ Bucket, Key, ContentLength, ContentMD5, ContentType }), { expiresIn, signableHeaders: new Set(['content-length', 'content-md5', 'content-type']) })` (`UploadPartCommand` likewise).
  - B2 bucket CORS, set with the `b2` CLI. Production: `[{"corsRuleName":"app","allowedOrigins":["<APP_ORIGIN>"],"allowedOperations":["s3_put","s3_get","s3_head"],"allowedHeaders":["content-type","content-md5","range"],"exposeHeaders":["etag"],"maxAgeSeconds":3600}]`. The dev bucket adds `http://localhost:3000` and the preview pattern. Never `*`.
  - B2 keeps old versions unless the lifecycle rule says otherwise, so deletes remove every version.
- **Integrity (F6).**
  - Whether B2 enforces `Content-MD5` and the signed `Content-Length`, and whether its single-PUT ETag equals the MD5, is **unconfirmed**. The web slice records all three on the dev bucket.
  - Multipart uploads, and single PUTs whose ETag isn't the MD5, are streamed once by `extract` and hashed in full before `ready`. Cost: B2 egress inside the free 3× allowance, and well under the 300 s function cap for files up to 1 GiB.
  - The type check sniffs with `file-type` over the range tokenizer (the real size is known, so ID3 tags are skipped properly; a 4 KB buffer would label anything starting with "ID3" as MP3). The sniffed family must match the extension (`mp3` ↔ `audio/mpeg`, `flac` ↔ `audio/flac`, `m4a`/`mp4`/`aac` ↔ `audio/mp4` or `audio/aac`, `wav` ↔ `audio/wav`), and `tracks.mime` comes only from the sniff.
- **Idempotency.**
  - `/complete` is guarded by the `pending → completing → completed` transition, and a retry returns the same track.
  - Play events use client UUIDs, and a stale event never fails its batch.
  - Jobs are enqueued with `dedupe_key` (`on conflict … do nothing`).
  - Favorites are PUT and DELETE.
  - Device registration is an upsert by client id, guarded by owner.
  - Byte releases happen once, through status transitions counted by the trigger.
- **Storage limit enforcement.**
  - The limit holds because the signed Content-Length binds stored bytes to reserved bytes, every session (covers included) reserves, sessions can't live past 7 days, and the counters are kept by triggers in the same transaction as the rows they count.
  - The reserve gate locks the profile row, so two tabs or devices can't both pass the check.
  - The hourly check locks the profile row before summing, so it can't lose an in-flight reservation; with the triggers, any drift it finds is a bug and is logged.
  - The admin can set a limit below usage: nothing is deleted, everything keeps playing and downloading, and uploads are refused (brand string 9 without the plan wording).
  - Cover WebP derivatives (about 50 KB per distinct image) aren't counted.
- **Races.**
  - *Playlist reorder and add:* every item mutation locks the playlist row first, so two writers never pick the same key; keys past 64 characters trigger a rebalance in the same transaction. The client updates optimistically and refetches on error.
  - *Queue edits on two devices:* server-side queue ops; playback fields belong to the active device (see PlaybackState).
  - *Library grouping vs cleanup:* the per-user advisory lock (see Schema decisions).
  - *The same file in two tabs:* the partial unique index on live sessions gives one session and one `resume`.
  - *A duplicate finishing first:* the unique index on tracks returns `duplicate` and the extra object is deleted.
  - *Concurrent job claims:* `SKIP LOCKED`.
- **Transactions and time.**
  - No network I/O inside a database transaction: S3 calls, Supabase admin calls and HTTP response writes happen between transactions.
  - `tunehold_app` has `statement_timeout = 60s`, `idle_in_transaction_session_timeout = 30s` and (PG17) `transaction_timeout = 90s`; jobs set the first two per transaction. So every commit lands within 90 s of its timestamps, inside the 120 s sync overlap.
- **Large libraries (50k tracks).**
  - Every list is virtualised (TanStack Virtual, FlashList) and every endpoint is cursor-paginated over partial indexes on live rows (measured 0.05 ms for a page on a 54k-track seed, against 30 ms with the old index).
  - Whole-library shuffle and search run in SQL. No client ever downloads every row except the mobile mirror, which pages through `/sync` (≤ 1,000 rows per page).
  - Database size: measured ~1.1 KB per track including indexes with an empty `tags_raw`; with the sort columns, their indexes and an allow-listed `tags_raw`, about 2 KB per track (estimate). 25k tracks ≈ 50 MB; three 50k-track libraries ≈ 300 MB, 60% of the Free cap. Past ~100k tracks in total, plan the move in OPEN 9 before the cap makes the project read-only. Watch `play_events` growth (~1 MB per month at the assumed listening).
- **Tag edge cases.**
  - Files with only ID3v1; a missing `albumartist` (handled by `regroup_batch`); compilations and "Various Artists"; multi-disc albums (the disc comes from the tag or a `CD1`/`Disc 1` folder).
  - Track numbers written as "3/12"; odd text encodings; multi-artist credits (v1 groups by the first artist and keeps the full credit as display text); MP3 VBR without a Xing header (`duration_estimated = true`).
  - MP4 with `moov` at the end (range reads handle it); WAV with RIFF INFO only.
  - Over-long or stuffed tags are truncated to 300 characters (the allow-listed copy in `tags_raw` keeps up to 500 per value).
  - CUE + single-file FLAC images aren't split in v1. ALAC in `.m4a` doesn't play in Chrome, Firefox or on Android (Media3 decodes it only with an FFmpeg extension that expo-audio doesn't bundle): it is flagged by codec, labelled "plays on iPhone and Safari", and skipped by the window planner where it can't play.
  - Fixture files for each case live in `packages/media` tests.
- **Parsing untrusted files.** Users upload files from anywhere, and they are parsed inside a Vercel function. `sharp` runs with `limitInputPixels: 40_000_000` and `failOn: 'error'`; `music-metadata` parses with `skipCovers: true`, and the embedded picture is read only when it declares ≤ 10 MB; the parse has a 120 s timeout, and parser errors or timeouts get 2 attempts, not 5, so a hostile file can't burn the Hobby plan's Active CPU.
- **Gapless and background audio.**
  - *Android:* background playback stops after ~3 minutes unless `setActiveForLockScreen` is active (expo-audio typings), so the call is mandatory, together with the Media3 foreground service from the plugin. `interruptionMode: 'doNotMixPersistent'` takes permanent audio focus (`AUDIOFOCUS_GAIN`); `'doNotMix'` would take transient focus, and a paused podcast app would restart when Tunehold pauses.
  - *iOS:* `UIBackgroundModes audio` comes from the plugin; `shouldPlayInBackground: true` is required (with its default `false`, the player pauses when the app leaves the screen).
  - *Gapless:* Media3 handles MP3 and AAC encoder delay; AVQueuePlayer and two HTML audio elements narrow the gap but don't promise sample-accurate playback. Accept near-gapless (gapless is a should), and test with a live album.
  - *Web on iOS Safari:* reuse one element (to verify) and hide the volume slider.
  - *Exit test for each platform:* repeat-all over an artist context of at least 3 albums, 2 h of locked playback, plus the failure drills below, on a real device.
- **Mobile player adapter** (`apps/mobile/src/player`; checked against the expo-audio 58.0.5 sources).
  - *Native window contract.* Append only, with `add()`. To change what comes next: `remove(i)` for every `i > currentIndex`, then `add()` in the new order. Never `insert()`, and never remove at or before `currentIndex` while playing: on iOS both rebuild the queue and restart the current track from 0. Played items stay, so lock-screen Previous has something to go back to; the playlist is compacted only while paused. `AudioSource.name = entryId`, and `trackChanged.currentIndex` is mapped through `playlist.sources[i].name`, never by index arithmetic. The `trackChanged` handler calls `updateLockScreenMetadata` first (metadata is one value per playlist, so it would otherwise show the previous track while locked), then does heavier work in chunks. A `player-core` unit test checks that the emitted op sequence never contains `insert` or a head remove.
  - *Recovery.* iOS never reports a failed item (only `.readyToPlay`), and on Android only the initial load calls `prepare()`, so after any player error the playlist stays idle. Hence: (a) a codec gate in the window planner (Android, Chrome and Firefox skip `alac`); (b) each window entry keeps `urlExpiresAt`, and before `play()` and on every track change, entries that would expire before now + their remaining duration + 1 h are re-signed; (c) preferred: a small `pnpm patch` of expo-audio that adds a playlist `retry()` (Android: `prepare()` again; iOS: forward `.failed` item status through `playlistStatusUpdate`); (d) without the patch: rebuild. On Android `status.error`, or when an iOS watchdog fires (playback intended but `currentTime` frozen for 10 s, or buffering for more than 20 s), create a new `AudioPlaylist` from `player-core` state with fresh URLs, `seekTo(position)`, call `setActiveForLockScreen(true, meta, opts)` on it, and only then `destroy()` the old one (to verify on Android 12+ while locked). At most 2 re-signs per track per 10 minutes; then the track is skipped with an error and logged.
  - *Failure drills (in the 1b and 1c done-when).* With `STREAM_URL_TTL_SECONDS=120` in dev: pause 3 min while locked, then resume; airplane mode for 60 s mid-track while locked; one ALAC file in an Android window; play a podcast app, start Tunehold, pause Tunehold, and the podcast must not restart by itself; on iPhone, "Play next" mid-song keeps the position. Playback must continue or recover without opening the app.
  - *Lossless over mobile data.* A per-device setting, "Lossless over mobile data: Ask (default) / Allow / Downloaded only", read with `expo-network` before each window fill. With "Ask", the first lossless track on cellular shows a one-time sheet; with "Downloaded only", the planner skips lossless members that aren't on the device. Each download toggle shows its size in MB, and settings show "streamed on mobile data this month" (counted on the device). FLAC streams at about 450 MB per hour, and replays download again because expo-audio has no stream cache.
- **Signed URL expiry vs long playback.**
  - Stream URLs last 2 h and are signed when a track enters the native window or the web preload, and re-signed before they can expire mid-track (see Recovery). The web player re-signs on any 403, `error` event or stalled load and seeks back, with the same 2-per-10-minutes bound.
  - Manifest URLs last 6 h; a download task re-signs through `stream-urls` when its URL expires in less than 10 minutes or after a 403.
  - Cover URLs use a signing date floored to the UTC day and a 48 h expiry. The URL is then identical all day, so browsers cache it, and mobile caches by `cacheKey = coverId`.
- **Mobile transfers** (checked against expo-file-system 58.0.5).
  - Uploads and downloads go through one queue saved in `expo-sqlite`: at most 3 tasks in flight, each URL signed just before its task starts.
  - On every launch and every return to the foreground the app reconciles: for each pending upload session it calls `POST /uploads/:id/complete` first (HeadObject decides, so a finished upload is never sent again); for each `.part` download it checks size and MD5, then renames or restarts it.
  - Android runs transfers inside the app process (OkHttp, no foreground service or WorkManager), so the app asks the user to keep Tunehold open while it transfers and resumes downloads with `Range` when they come back. A WorkManager or `dataSync`-service local module is a later, separately sized option.
  - iOS background sessions keep in-flight tasks going, but a task that finishes after the app was killed is never handed back to JS; the launch reconcile covers it. Background sessions don't expose `allowsCellularAccess`, so the app listens to `expo-network` and pauses active downloads when the connection turns cellular and the device's cellular switch is off.
- **Offline cache integrity (F5).**
  - Each file goes to `….part`, is checked for size and MD5 (`file.info({ md5: true })`), then renamed and registered.
  - The device index: `offline_files(track_id, rel_name, size, md5, verified_at)`, `offline_scopes(scope_type, scope_id, created_at)`, `offline_file_scopes(track_id, scope_type, scope_id)`. A file is deleted only when its last scope link is gone. After each `/sync`, every downloaded scope is resolved again from the mirror: additions are queued, removals unlinked.
  - Before a scope download starts, the device sums `sizeBytes` over every manifest page and refuses when it exceeds `Paths.availableDiskSpace` minus a 2 GB reserve. "Library" asks for explicit confirmation and shows the total.
  - Only relative names (`{trackId}.{ext}`) are stored; the path is built at runtime (`new File(Paths.document, 'tunehold/audio', name)`), because the iOS container path can change across app updates. At startup, index rows whose file is missing are dropped.
  - Files live in `Paths.document/tunehold`, not the cache directory. The `expo-sqlite` database opens inside that folder (`openDatabaseAsync(name, options, directory)`), and holds the device id and the Supabase session too. iOS: the `backup-exclude` module sets `isExcludedFromBackup` on the folder. Android: `allowBackup=false` and `dataExtractionRules` (a small config plugin) exclude it from cloud backup and device transfer. A restored or migrated phone therefore starts signed out, with an empty index and a new device id.
  - Covers: the mirror stores only `coverId`. The 600 px cover is downloaded with each track to `Documents/tunehold/covers/{coverId}.webp` and used for the UI and the lock-screen `artworkUrl` offline; online, URLs come from `GET /covers/urls`, cached per UTC day.
  - Playback is local-first.
  - Tombstones and `deleted`/`disabled` rows remove files at the next sync; there is no check-in (accepted in `fixes.md`; the takedown check-in question is deferred with the legal work).
  - Downloads are wiped only on an explicit "Sign out" tap or a `401 device_revoked`. Any other session loss (a rejected refresh token, a disabled-then-enabled account) keeps the files, shows "Sign in again", and offline playback keeps working.
  - Downloads are Wi-Fi only unless the device's cellular switch is on (`expo-network`).
- **Search over 50k tracks.**
  - Trigram GIN on normalised `search_text`; every word must match, with `%`, `_` and `\` escaped. Estimated well under 50 ms per user library (unmeasured: the slice records `EXPLAIN ANALYZE` on a 50k-row seed).
  - One- and two-character queries use prefix matching.
  - Recent searches are stored on the client only (no table).
- **Time zones.**
  - Everything is UTC. `play_events.client_tz` drives the history page and the history CSV only.
  - The "recently played" shelves take the viewer's current `?tz=`.
  - No scheduling, so daylight saving doesn't matter anywhere else.
- **Multi-tenancy and privacy among friends.**
  - RLS policies for the API role, owner-scoped repositories, composite owner FKs, the Data API off, 404s for other users' ids, server-built storage keys only, and a Vitest suite generated from the route table that calls every `:id` route as user B against user A's ids (including B passing A's `coverUploadId` → 404) and a two-device playback case (the phone plays, the web takes over, the phone keeps its song and shows "Not synced").
  - The admin sees usage, never libraries.
- **Browser security.** Session cookies from `@supabase/ssr` are readable by JavaScript, so XSS means token theft: tag text is rendered only as text, the CSP above applies to app routes, `server-only` and the import boundaries keep server secrets out of client bundles, and `/api/v1` sends no CORS headers.
- **Account deletion.**
  - `purge_user` deletes the user's objects, then their rows, then the auth user.
  - It needs a password sign-in less than 5 minutes old (JWT `amr`), so a stolen session can't wipe a library.
  - The `profiles → auth.users` key is `on delete restrict`, so the dashboard can't orphan files.
  - Grace period: OPEN 12 (proposed: 7 days, cancellable by the admin).
- **Rate limits and file sizes.**
  - The Postgres limiter above protects Vercel Hobby's Active CPU and invocations and B2's daily free transactions against a client retry loop or a stolen token. Supabase Auth has its own limits.
  - `MAX_FILE_BYTES` defaults to 1 GiB (B2's single-PUT ceiling is 5 GB). Covers are ≤ 10 MiB.
  - Revisit all of them at any launch.
- **Email deliverability.** None in v1: links are shared by chat, which is why `/auth/confirm` is side-effect free on GET. Self-service reset (F10) waits for a domain and Resend.
- **Realtime.** None. Connect-style remote control is a could. Devices pick up the state on focus or open.
- **Platform limits.**
  - Vercel Hobby: functions max 300 s, request bodies 4.5 MB, cron once a day, personal non-commercial use only.
  - Supabase Free: pauses after a week idle (the hourly sweep counters this; to verify that pooled queries count as activity), 500 MB database, and no usable backups (nightly encrypted `pg_dump`).
  - GitHub: scheduled workflows in public repos stop after 60 days with no repository activity, and private repos have a minutes budget (see Costs).
- **Monorepo React versions.** Expo SDK 58 pins a React version, so `apps/web` uses the same one. `.npmrc` uses `node-linker=hoisted` if Metro needs it; the scaffold task decides with a working dev build.

---

## Build order

Sizes follow `WORKFLOW.md`. Each milestone lists its screens, tables and routes. Durations are ranges for one student at ~15 h/week (estimates).

### 0. First code task: scaffold + landing page (medium)

- **What:**
  - The monorepo with `packages/config` and `packages/tokens`.
  - `apps/web` with the landing page at `/` (`app/(marketing)/page.tsx`, copy verbatim from `launch/landing.md`) and `GET /api/v1/health`.
  - The Vercel project (`iad1`) and `ci.yml` (lint, typecheck, build, sweep gate).
- **Screens:** S01. **Tables:** none. **Routes:** `/api/v1/health`.
- **Done when:** the page is live on `*.vercel.app`; `sweep.py apps/web --config replica/brand.json` exits 0; `contrast.py` passes on any new colour pair; there's no horizontal scroll at 320 px.

### 1. Vertical slice

**1a. Web (large; tracks: backend, frontend).** A user signs in by invite, uploads one file, sees it in the library and plays it on the web.
- **Screens:** S03, `/welcome`, S18 (single file), S07 (minimal track and album lists), S10, S12 (play, pause, seek, Media Session).
- **Tables:** migration 0000 applied in full after the "Schema checks before 1a". Used: `profiles`, `invites`, `devices` (web), `artists`, `albums`, `covers`, `tracks`, `upload_sessions`, `jobs`, `rate_limits`.
- **Also:** the `tunehold_app` login and the request transaction; Auth settings applied to both projects; security headers; the rate limiter on the 1a routes; B2 CORS as written.
- **Routes:** `GET` and `POST /auth/confirm`, `POST /admin/invites`, `GET /me`, `POST /me/activate`, `PUT /devices/:id`, `POST /uploads/batch` (single mode only), `GET /uploads/:id`, `POST /uploads/:id/complete`, `DELETE /uploads/:id`, `GET /library/tracks`, `GET /library/albums`, `GET /albums/:id`, `GET /tracks/stream-urls`, `/api/cron/sweep` (job retry, session expiry, counter check), plus `seed.ts` for the founder's admin account.
- **Done when:**
  - The founder, on the deployed URL, uploads one MP3 and one FLAC; both appear with tags and cover and play with seek.
  - The second-user suite (generated from the route table) is green for these routes.
  - An invite link opened twice with GET, then continued with POST, still works.
  - The B2 findings are recorded in the spec: a PUT whose body length differs from the signed one gets 403? Content-MD5 enforced? ETag = MD5? CORS works?
- **First song on the web:** weeks 4–6 (estimate).

**1b. Android (large).**
- **Scope:** the Expo app on SDK 58 (stable, or the `next` tag pinned exactly), an EAS development build (APK), login, library, album, artist, mini player, background playback and the lock screen. Plus `packages/player-core` natural order, repeat and the window planner with the codec gate (no shuffle yet), `GET /contexts/:type/:id/tracks?order=natural`, and the mobile player adapter contract with its recovery path.
- **Tables:** `devices` (with the session link). **Routes:** `PUT /devices/:id`, `GET /contexts/:type/:id/tracks`, `GET /artists/:id`, plus the 1a library routes.
- **Done when:** repeat-all over an artist context of at least 3 albums, 2 h locked on a real Android phone, with lock-screen next and previous, and the failure drills pass. Whether `auth.sessions` can be deleted for remote sign-out is recorded.
- **First song on Android:** weeks 6–9 (estimate).

**1c. iOS (medium–large).**
- **Scope:** the same app through EAS iOS and TestFlight internal testing, once 1b has passed and the Apple membership (OPEN 1) is active. Time for hardening the adapter against AVQueuePlayer's behaviour. Until then iPhone friends use the web app in Safari: streaming and lock-screen controls, no offline.
- **Done when:** the same 2 h locked test and the failure drills on a real iPhone, including "Play next mid-song keeps the position".
- **First song on iPhone:** 1–3 weeks after the membership is active (estimate).

### 2. Must-haves by area

The orchestrator can split these into parallel tracks. Each area becomes a feature spec. **H1 comes before Area B's mobile work**, so the mobile player is built local-first on the mirror from the start.

| area | screens | tables | routes | `features.csv` rows closed |
| --- | --- | --- | --- | --- |
| **A. Upload and library** (F01, F6) | S18 full (folder, multipart, resume, partial failure, storage full, unsupported, upload from mobile), S07 (filters, sort, search in library), S11, S05 | `upload_sessions`, `tracks`, `albums`, `artists`, `covers`, `jobs` | `uploads/*`, `tracks/:id` DELETE, `tracks/bulk-delete`, `tracks/:id/reprocess`, `library/*`, `artists/:id`, `home`; jobs `apply_sidecar_cover`, `regroup_batch`, `purge_track`, `library_cleanup` | Upload audio files; Read ID3 tags on upload; Your Library with filters; Sort and search inside Your Library; Album page built from tags; Artist page built from tags; Delete tracks and free storage; Bulk folder upload with resume; Keep stored copy bit for bit; Home with recently played and quick picks; also Duplicate detection on upload (should) |
| **H1. Mobile mirror and sync** (fix F5, first half), medium | settings (sync status) | `tombstones`, `devices` | `sync`, `covers/urls`, `devices/:id` DELETE; the play-event outbox | (enables Area B mobile and H2) |
| **B. Player** (F02, F04; fixes F2, F4) | S12 full, S13, S14 on web and mobile | `playback_state`, `play_events` | `playback-state` GET/PUT, `playback-state/queue`, `contexts/:type/:id/tracks` (shuffle), `play-events`, `stream-urls` | Play pause skip previous seek; Persistent now playing bar across navigation; Full screen now playing view; Volume and mute; Shuffle; Repeat (off all one); Queue view with reorder and remove; Play next and add to queue; Lock screen and media session controls; Background playback on mobile; also Resume where you left off across devices (should) and Shuffle whole library and shuffle the queue (should) |
| **C. Playlists and favorites** (F03, F05) | S09, S16, S17, S08 | `playlists`, `playlist_items`, `favorites`, `tombstones` | `playlists*`, `favorites*` | Create rename delete playlist; Add and remove tracks in a playlist; Reorder tracks by drag; Liked Songs (heart a track), shipped as Favorites |
| **D. Search** (F06) | S06 | (indexes) | `search` | Search across own library (tracks albums artists playlists) |
| **E. Admin, account, settings** (F10 by admin link) | admin page, S21, S22 as "Account and space" (no plan), S03 "Forgot password?" → "Ask the person who invited you for a reset link" | `profiles`, `invites`, `devices` | `admin/*`, `me*`, `devices` (GET, PUT) | Account settings (password and delete account; email change waits for SMTP → partial); Storage quota per plan with usage meter → shipped as the admin-set limit and space meter (partial: no plans); Password reset by email → admin link until a domain exists (partial) |
| **F. Export** (fix F7, export part) | S21 / account page | `playlists`, `play_events`, `tracks` | `export/*` | Export library on demand: playlists M3U8/CSV, history CSV and library CSV now; audio files later → partial |
| **G. Design rules** (fix F3) | all | — | — | Dark theme UI; Responsive web layout; No promotional pop-ups or custom rating prompts (policy) |
| **H2. Offline downloads** (F07, fix F5), **L**, last | S24, download toggles on S08–S10 and S16, settings (cellular switch, lossless-over-mobile setting, space used) | `downloads`, `devices` | `downloads/manifest`, `devices/:id/downloads` (PUT, remove) | Download for offline on mobile; also Offline indicator and downloaded filter (should) and Storage settings for downloads (should) |

### 3. Should-haves, then could-haves

- **Should:**
  - Edit track metadata and cover art: S19, `PATCH /tracks/:id`, `PATCH /albums/:id`, `POST /covers/uploads`.
  - Recently played plus a full history page: `GET /history`, using `play_events`.
  - Personal per-track play counts: already counted; this is UI work.
  - Smart playlists: `playlists.kind = 'smart'`, rules on genre, year, date added and play count (the fixed grammar above).
  - Playlist cover and description: S17.
  - M3U/M3U8 import: `POST /playlists/import`.
  - Recent searches: on the client.
  - Home shelves: most played, not played in a while.
  - Gapless playback: verify per platform.
  - Sleep timer: client only.
  - Keyboard shortcuts on the web: S27.
  - Sign in with Google and Apple: after the domain decision. If any social login ships on iOS, Apple sign-in comes with it.
  - Audio quality setting: hidden until the transcode worker exists.
- **Could:**
  - Grid/list view; crossfade; playback speed.
  - Lyrics from user `.lrc` files: S15, a `lyrics` column or sidecar.
  - Lossless playback: already true for FLAC originals.
  - Playlist folders and more pins (new tables when built); browse by genre tag; tablet layout.
  - Connect (realtime remote control, later).
- **Optional milestones, triggered by the founder:**
  - The Subsonic `/rest` layer (~1 week).
  - `workers/transcode` (AAC 256 kbps for cellular streaming, ALAC, WAV).
  - Full audio export as a signed-URL manifest.
  - Android background transfers through a WorkManager or `dataSync`-service local module.
- **Not built (deferred by `deferred.md`):**
  - Sign up with email: replaced by invites.
  - Plan and billing management; Free and paid plans with checkout; Family or duo plan; Student discount.
  - Report content (copyright).
  - Share a playlist by link; Public profile with public playlists; Collaborative playlist; Follow users.
- The `skip` rows stay `skip`. The car row is re-checked below.

### 4. Fixes from `/replica-entrepreneur`, mapped

| fix | where it lands |
| --- | --- |
| F1 every control on every plan | Moot without plans: every account has every control by construction. No entitlement checks exist in code. |
| F2 playlists play only their own tracks | `player-core`: a context plays its own members and stops at the end (`ended`); autoplay off by default and drawn only from the user's own library; S14 shows "Next from: {context}" and a clear end state. Area B. |
| F3 quiet, music-only app | Policy in Area G: no promos, no rating prompts, no push notifications in v1, and a home built only from the library and history. |
| F4 shuffle for large collections | The PlaybackState spec above; the keyed-hash cycle in SQL and on the device; `contexts/:type/:id/tracks?order=shuffle`; reshuffle; shuffle library and queue. Area B. |
| F5 offline downloads | Areas H1 and H2: verified files in a backup-excluded folder, per-scope links, tombstones at the next connection, remote device revoke that really signs out, Wi-Fi by default. |
| F6 bulk upload, stored copy bit for bit | The audio pipeline and Area A: immutable object keys, signed lengths, MD5/ETag integrity with a full hash for multipart, per-user duplicates, no cross-user deduplication, M3U import (should). |
| F7 export on demand | Area F for playlists, history and the library list. Full audio export is an optional milestone. The over-quota and retention rules are deferred. |
| F8 collector tools | `tracks.play_count` and history (should), smart playlists (should), search inside a playlist (`q` on the items route), an A–Z scrubber (client, over the sort keys); more pins later. |

`fixes.md` section 7 items for this phase, answered:
- **PlaybackState:** specified above.
- **Removal to offline devices:** at the next connection through `/sync` (the takedown check-in question is deferred with the legal work).
- **Storage cost model:** see Costs.
- **Thin slice:** milestone 1.
- **Subsonic:** see below.
- **Car skip:** re-checked below.
- **Billing model and tracklist-only sharing:** deferred by `deferred.md`, and nothing in the schema blocks them. Sharing would add a `share_links` table and match against the recipient's own tracks by MD5 or tags.

---

## Landing page

- **Where:** `apps/web/app/(marketing)/page.tsx`, served at `/` by the same Vercel project and domain as the app. `export const dynamic = 'force-static'`, server components only, no forms, analytics or third-party scripts. Atkinson Hyperlegible Next (400/600/700) is self-hosted through `next/font`. It gets the security headers with a non-nonce `script-src` (see Conventions).
- **Theme:** a dark band (header and hero) from the `color` block, and a light body from `color-light`.
- **Status tags:** "Works today" / "In progress" come from `apps/web/src/marketing/status.ts`, updated at each milestone, and flip only when a feature works for an invited user.
- **Header:** the "Log in" link appears only once `/login` exists (from milestone 1a).
- **Order:** it is **the first code task** (milestone 0, medium), and it proves Vercel and CI before any backend exists.
- **Copy:** verbatim from `launch/landing.md`. Two lines describe things v1 does not build, so they must keep their "In progress" tags or change (OPEN 14):
  - card 2's "Tunehold makes a separate, lighter copy for streaming": v1 streams originals; the copy comes only with the optional transcode worker;
  - card 1's "If an upload is interrupted, it picks up where it stopped": outside Chromium, picking up means dropping the folder again.
- **Robots:** `noindex` is the founder's call (`landing.md`).

---

## Costs at personal scale (estimates)

Assumptions (the same as the judge pass): 3 users holding 20,000 MP3 (~192 GB) and 5,000 FLAC (~150 GB) plus ~1 GB of covers ≈ **343 GB**. Listening is 180 h/month in total, which comes to ~37 GB/month of egress (worst case ~111 GB with downloads). USD, before Colombian VAT and bank fees (not checked).

| item | per month (estimate) | basis |
| --- | --- | --- |
| Backblaze B2 storage | ≈ $2.3 ((343 − 10 free) GB × $6.95/TB) | B2 pricing page, via search snippets (backblaze.com is blocked from this container; re-check before relying on it) |
| B2 egress and API calls | $0 (egress free up to 3× stored ≈ 1 TB, which also covers the one-off full-file hash of multipart uploads, ~150 GB at the first import; API calls free on pay-as-you-go per the snippets) | same |
| Supabase Free (Postgres + Auth), 2 projects | $0 (DB ~50 MB for 25k tracks, ~300 MB for three 50k libraries, of 500 MB; 3 MAU of 50,000) | `supabase/supabase` `packages/shared-data/plans.ts`; per-track size from the schema review's measurement |
| Vercel Hobby | $0 (audio bypasses Vercel; extracting and hashing the whole import ≈ 1 Active-CPU-h of 4 included) | vercel.com/docs/plans/hobby (via search); function limit 300 s (Vercel changelog, via search 2026-10-04) |
| GitHub Actions | $0. Public repo: unlimited standard minutes. Private repo: 2,000 min/month, each job rounded up to a whole minute; budget ≈ 720 (hourly sweep) + 90 (nightly backup) + ~500 (CI) ≈ 1,300 min | search results 2026-10-04 (cicdcalculator.com, macrostack.net); GitHub's billing page not fetched |
| EAS Build Free | $0 (30 builds/month, up to 15 iOS; a rebuild every 60 days keeps TestFlight builds alive) | docs.expo.dev/billing/plans (via search) |
| Resend Free (once a domain exists) | $0 (3,000/month, 100/day) | resend.com/pricing (via search) |
| **Total variable** | **≈ $2.3/month** | R2 instead: ≈ $5.0/month; Supabase Storage instead: ≈ $30/month |

**Sensitivity.** If each of the 3 users holds that library (~1 TB): B2 ≈ $7.1/month, R2 ≈ $15.3/month. Egress is still inside B2's allowance, and the database is ~150 MB at 75k tracks.

**Why the sweep is hourly, not every 30 minutes.** On a private repo, a 30-minute sweep alone uses 1,440 of the 2,000 free minutes (every run bills at least a minute), leaving too little for CI. Work normally runs inline through `after()`, so hourly only delays retries and expiries. With a public repo, 30 minutes is free.

**Fixed costs.**
- **Apple Developer Program:** US$99/year, required for TestFlight to friends' iPhones and even for a development build on a physical iPhone (except Xcode on a Mac with a free personal team: 7-day signing, own phone only). Individuals get no fee waiver; TestFlight builds expire after 90 days, and friends' builds stop working if the membership lapses. Pay when 1b passes on Android (OPEN 1). Alternatives: web in Safari (no offline), or the Subsonic milestone with a free third-party client.
- **Domain:** about US$10–15/year, optional, not fetched.
- **Android:** $0 by sideloaded APK. Google Play Console is US$25 one-time, only if Play internal testing is ever wanted. Google's developer verification is planned to expand globally in 2027. Once it reaches Colombia, the free limited-distribution account (up to 20 devices) is the $0 path.
- **Year one:** about $99 + ~$12 (domain) fixed, plus ≈ $2.3/month variable.

**Time to first song** (estimates for one student at ~15 h/week):
- Milestone 0: days 1–4.
- Web: weeks 4–6.
- Android: weeks 6–9.
- iPhone: 1–3 weeks after the Apple membership is active (paid once 1b passes).
- Must-haves (A–G, with H1): weeks 9–16.
- Offline downloads (H2): weeks 15–20.

---

## Subsonic and cars (the decision `fixes.md` asks for)

**The decision: no Subsonic layer in v1.** Native Expo stays, as the founder chose. A Subsonic-compatible `/rest` adapter is an **optional milestone of about 1 week** that the founder can trigger, mainly as the $0 route to iPhone friends instead of the Apple fee.

How it would work:
- It is a thin layer over the same services and ids.
- Each client gets its own app password, stored encrypted with AES-GCM in a new `app_passwords` table.
- `stream` and `download` answer with a 302 to a presigned B2 URL, because Vercel must not proxy audio. Test redirect handling with 2–3 clients before committing.

Third-party clients don't follow F2, F4 or F5.

**Cars stay `skip` for v1.** `expo-audio` exposes no CarPlay or Android Auto API (checked against the 58.0.5 typings in the judge pass). The only cheap route to the car is a third-party Subsonic client that supports it, so check each client's own listing before counting on it. Revisit with the playback library if the founder wants the car.

---

## Open decisions for the founder

1. **Apple Developer Program (US$99/year).** Proposed: pay when milestone 1b passes on Android and the adapter is stable, not on a calendar week; that starts the yearly fee and the 90-day TestFlight clock only when an iOS build is useful. Default distribution: TestFlight internal testing, with each friend added to the App Store Connect team as a user with the Marketing role and access to this app only (each needs an Apple ID). Alternative: EAS ad hoc builds (each iPhone's UDID registered, at most 100 a year, Developer Mode on). Rebuild every 60 days; put the renewal date in the calendar. Other options: defer it, and iPhone friends use the web app in Safari; or build the Subsonic milestone, so they use a free client.
2. **Subsonic `/rest` milestone:** yes, no or later (≈ 1 week, a second route surface, weaker auth by design).
3. **Domain:** buy `tunehold.com` now (~US$10–15/year), or stay on `*.vercel.app`. A domain unlocks Resend SMTP and self-service invites and reset (F10). The mobile bundle id no longer waits on it: it is frozen as `app.tunehold.mobile` (Apple doesn't check domain ownership); change it now or never, because changing it after the first build means a new app and lost downloads.
4. **Object storage:** B2 (default, ≈ $2.3/month, Content-MD5 and signed-length enforcement unconfirmed, CORS through its CLI), or R2 (≈ $5.0/month, zero egress, simpler CORS). Both need a card past the free 10 GB.
5. **Expo SDK at the mobile slice:** SDK 58 is required: stable if it has shipped by 1b, otherwise the `next` tag pinned exactly. SDK 57 (or a single `AudioPlayer`) is not a fallback: outside the app it offers only seek ±10 s, with no next or previous on the lock screen, headphones, Bluetooth or the car. If `AudioPlaylist` fails on a device, the fallback is the expo-audio patch, or a local Expo module over Media3 and AVQueuePlayer (sized large).
6. **Mac:** does the founder have one? It isn't needed for EAS cloud builds, but it is needed for the iOS Simulator, local iOS builds and debugging the backup-exclude module. Without one, that module and the iOS adapter can only be tested on a TestFlight or ad hoc build.
7. **Android distribution later:** the free limited-distribution account (≤ 20 devices) or Play Console ($25) once verification reaches Colombia (2027).
8. **Initial storage limit per friend, and the real size and format mix of the founder's library.** This sets the B2 cost (~$7/TB-month), the import time and the database size.
9. **Supabase Free limits:** accept them (a week-idle pause countered by the hourly sweep; the nightly dump as the only backup; 500 MB, about 100k tracks in total at ~2 KB each with headroom for history), or move to Neon Free or Supabase Pro ($25/month) later.
10. **Lossless over mobile data.** FLAC streams at about 450 MB per hour, and replays download again. v1 ships the per-device "Lossless over mobile data" setting with **Ask** as the proposed default (or Allow, or Downloaded only), plus sizes on download toggles and a monthly counter. Separately: if friends mostly listen on mobile data, schedule the optional AAC 256 transcode worker before H2. Downloads default to Wi-Fi only either way.
11. **Repository visibility and name.** Public means unlimited Actions minutes and a 30-minute sweep. Private means the hourly sweep and the minutes budget above. `brand.md` asks to rename the repo before it is public or connected to a host, and Vercel builds project names and preview URLs from it. Either way, production secrets stay in the GitHub Environment `production`.
12. **Account self-deletion:** proposed default now: re-enter the password, then a 7-day grace period during which the admin can cancel it (audio isn't backed up, so a stolen session shouldn't be able to wipe a library at once). Alternatives: an immediate purge after the password check, or admin-only for now.
13. **Favorites label:** "Favorites" or "Keepers" (`brand.md`). Code identifiers stay `favorites`.
14. **Landing copy:** keep card 2's "lighter copy for streaming" sentence (it describes the optional transcode worker) under "In progress", or drop it; soften card 1's resume line for non-Chromium browsers; and the `noindex` choice.
15. **Accepted formats and size cap:** MP3, AAC/M4A, FLAC and WAV up to 1 GiB per file (the proposal). ALAC: accept and flag as "plays on iPhone and Safari" (Android, Chrome and Firefox can't decode it, and the player skips it there; the proposal), or reject until the transcode worker exists.

---

## Sources

Fetched or searched on 2026-10-04 and 2026-10-05 in this phase, the judge pass and the design reviews. Search-snippet sources are marked "via search".

- Supabase plans and limits: `github.com/supabase/supabase` `packages/shared-data/plans.ts` and `pricing.ts`. SMTP limits: `apps/docs/content/guides/auth/auth-smtp.mdx`. Direct connection is IPv6-only; use the session pooler from GitHub Actions: `supabase.com/docs/guides/database/connecting-to-postgres` (via search).
- Supabase Auth (GoTrue) admin link generation, invite for a confirmed user → `email_exists`: `github.com/supabase/auth` `internal/api/mail.go` (fetched 2026-10-05).
- Backblaze B2 storage and transaction pricing: `backblaze.com/cloud-storage/pricing`, `/cloud-storage/transaction-pricing` (via search). B2 requires Content-MD5 on PutObject when Object Lock is on: `github.com/drakkan/sftpgo/issues/1336` (via search). B2 rejects the AWS SDK's new checksum headers; use `WHEN_REQUIRED`: `github.com/aws/aws-sdk-js-v3/issues/6810`, `github.com/jschneier/django-storages/issues/1498`, `github.com/nocobase/nocobase/issues/6872` (via search).
- Cloudflare R2 pricing: `developers.cloudflare.com/r2/pricing` (cloudflare-docs `r2/pricing.mdx`).
- Vercel Hobby: `vercel.com/docs/plans/hobby` (via search). Function duration 300 s on Hobby with Fluid compute: `vercel.com/changelog/higher-defaults-and-limits-for-vercel-functions-running-fluid-compute` (via search). vercel.com itself is blocked from this container.
- GitHub Actions free minutes (2,000/month for private repos, jobs rounded up to whole minutes): `cicdcalculator.com/github-actions-free-tier`, `macrostack.net/pricing/github-actions` (via search).
- Expo and expo-audio versions, typings, sources and changelog: npm registry dist-tags and package tarballs (expo 58.0.3 `next` / 57.0.26 `latest`; expo-audio 58.0.5 and 57.0.5: `ios/AudioPlaylist.swift`, `android/.../AudioPlaylist.kt`, `AudioRecords.kt`, `build/AudioConstants.d.ts`, `build/Audio.types.d.ts`, `plugin/build/withAudio.js`; expo-file-system 58.0.5: `ios/FilePickingUtils.swift`, `build/NetworkTasks.types.d.ts`, `android/.../FileSystemUploadTask.kt`, `build/Paths.d.ts`; expo-sqlite 58: `build/SQLiteDatabase.d.ts`). EAS plans: `docs.expo.dev/billing/plans` (via search).
- react-native-track-player: npm `latest` 4.1.2; v5 only as `5.0.0-alpha` nightlies (last 2025-09-24).
- Apple Developer Program and fee waivers: `developer.apple.com/programs`, `developer.apple.com/help/account/membership/fee-waivers` (via search).
- Android developer verification and the Play Console fee: `developer.android.com/developer-verification`, `support.google.com/googleplay/android-developer/answer/6112435` (via search).
- Resend pricing: `resend.com/pricing` (via search).

---

## Review log

Three design reviews ran on 2026-10-04 against the first version of this document and `schema.sql` (the first executed the schema on PostgreSQL 16.14 with a 3-user, 54k-tracks-each seed; the third read the expo-audio, expo-file-system and expo-sqlite sources). Each finding was checked against the files (and, for mobile and GoTrue claims, the package sources) before it was applied. **48 findings: 48 applied (7 with an adjusted or different fix: 1.4, 1.5, 1.7, 1.14, 2.7, 2.17, 2.20), 0 rejected.**

| # | sev | finding | verdict |
| --- | --- | --- | --- |
| 1.1 | high | Hourly reconcile loses in-flight reservations; a later release breaks the CHECK | Applied: counters kept by triggers on `tracks` and `upload_sessions`; the reconcile locks the profile, then sums, and logs drift. |
| 1.2 | high | `updated_at`-only sync cursor can't page a bulk write | Applied: keyset `(updated_at, id)` per entity, overlap only at run start, `clock_timestamp()`, role timeouts, no network I/O in transactions. |
| 1.3 | med | `library_cleanup` races extract (NULL `album_id`, lost cover objects) | Applied: per-user advisory xact lock on library writes; cover objects keyed by row id; objects deleted after commit. |
| 1.4 | med | Natural-order cursors mix collations | Applied, adjusted: `sort_*` columns `COLLATE "C"` (accent-folded, ≤ 100 chars) are sent to devices instead of recomputed there; jsonb cursor; disc and track `NOT NULL DEFAULT 0`. |
| 1.5 | med | Whole-document PUT lets a queue edit rewind the playing device | Applied, adjusted: active-device ownership plus server-side queue ops; the PUT needs no `If-Match`, so queue edits never force a merge. |
| 1.6 | med | One purged track id blocks the play-events outbox | Applied: client snapshot, set-based LEFT JOIN insert (devices too), `played_at` clamped, per-event outcomes. |
| 1.7 | med | `tags_raw` unbounded against the 500 MB cap | Applied, tightened: allow-list, 500-character values, an 8 KB CHECK (not 16 KB); sessions pruned after 30 days; size estimate redone. |
| 1.8 | low | 1000-char CJK title overflows the index row; extract never gives up | Applied: tag CHECKs ≤ 300, title index replaced by `sort_title`; the last failed attempt marks the track `failed`. |
| 1.9 | low | Library page indexes unusable with the status IN filter | Applied: partial indexes on live rows for every sort. |
| 1.10 | low | Fractional keys grow until the CHECK fails | Applied: playlist row lock, rebalance past 64 chars, deferrable unique constraint. |
| 1.11 | low | Tombstone gaps (cascades, re-favorite, `deleted` status) | Applied: client cascade rules, tombstones first, PUT favorite deletes its tombstone, `deleted` in `SyncTrackDto`. |
| 1.12 | low | Sidecar covers skip the storage limit | Applied (with 2.1): covers reserve, 10 MiB CHECK, inbox cleanup. |
| 1.13 | low | Device FKs not composite | Applied. |
| 1.14 | low | "Not executed" notes out of date | Applied, adjusted: the notes record the PG16.14 run of the previous revision and state that this revision is not executed yet. |
| 2.1 | high | Limit enforced on the declared size only | Applied: signed Content-Length, 7-day session cap, cover sessions reserve, server-side ListParts, extension whitelist, reserved = declared CHECK, B2 403 gate in 1a. |
| 2.2 | med | `coverUploadKey` lets a user name another user's object | Applied: `coverUploadId` resolved by owner; no route accepts a storage key. |
| 2.3 | med | Link previews burn invite tokens; re-invite fails | Applied: GET renders, POST verifies; recovery-type regeneration (GoTrue source checked); invited → `/welcome`; OTP expiry 86400 s. |
| 2.4 | med | Remote sign-out leaves the session working | Applied (with 3.8): `devices.auth_session_id`, `401 device_revoked`, wipe derived from the session. |
| 2.5 | med | Reconcile overwrites counters | Applied: same fix as 1.1 (triggers instead of app-side arithmetic). |
| 2.6 | med | RLS described as a backstop the owner role bypasses | Applied, option (a): `tunehold_app` role, owner policies, `set_config` per request transaction. |
| 2.7 | med | Background upload URLs expire before queued tasks start | Applied, different fix: foreground-first queue, ≤ 3 in flight, each signed just before start, launch reconcile; no 6 h mobile TTL needed. |
| 2.8 | low | 12 h stream URLs, unbounded re-sign loop | Applied: 2 h streams, 6 h manifests, 2 re-signs per track per 10 min. |
| 2.9 | low | Device FKs, upsert guard, playback ids | Applied. |
| 2.10 | low | 4 KB `file-type` sniff calls anything "ID3…" MP3 | Applied: sniff over the range tokenizer, family must match the extension. |
| 2.11 | low | No parser resource limits | Applied: `limitInputPixels`, `skipCovers` with a 10 MB picture cap, 120 s parse timeout, 2 attempts on timeouts. |
| 2.12 | low | CSV injection and zip slip in exports | Applied. |
| 2.13 | low | Smart-rule compiler and `LIKE` unbounded | Applied: zod grammar, rules size CHECK, `LIKE` escaping, `q` caps. |
| 2.14 | low | Auth settings not written down | Applied: checked-in list, `supabase/config.toml`, deploy check. |
| 2.15 | low | Admin and cron gaps | Applied. |
| 2.16 | low | No rate limiter | Applied: Postgres fixed-window limiter through a `SECURITY DEFINER` function. |
| 2.17 | low | No CSP or headers; secrets could reach client bundles | Applied, adjusted: nonce CSP on app routes (the static landing keeps a non-nonce CSP); `server-only` only in `apps/web/src/server` (it would break Vitest in packages); no CORS headers; Bearer wins over cookies. |
| 2.18 | low | B2 CORS rule and env scoping unspecified | Applied. |
| 2.19 | low | Backups unencrypted; secrets scope; restore order | Applied: `age`-encrypted dumps, SSE-B2, GitHub Environment `production`, auth tables dumped and restored first. |
| 2.20 | low | Session + "DELETE" purges a library at once | Applied, adjusted: recent password sign-in checked through the JWT `amr` timestamp (`iat` also changes on refresh); the 7-day grace becomes OPEN 12's proposed default for the founder to decide. |
| 3.1 | high | expo-audio playlists can't recover from errors or expired URLs | Applied: codec gate, re-sign before expiry, `pnpm patch` preferred with a rebuild fallback, failure drills in 1b and 1c (sources checked). |
| 3.2 | med | iOS `insert` and head removes restart the current track | Applied: append-only window contract and a unit test on the op sequence (sources checked). |
| 3.3 | med | SDK 57 fallback has no next/previous outside the app | Applied: SDK 58 required for 1b; OPEN 5 rewritten (typings checked). |
| 3.4 | med | `doNotMix` takes transient focus; background flag and mic permission | Applied: `doNotMixPersistent`, `shouldPlayInBackground: true`, plugin without recording permissions (sources checked). |
| 3.5 | med | Mobile transfers are foreground-only on Android and lost after a kill on iOS | Applied: saved transfer queue, launch reconcile, copy cleanup and pick cap, cellular watch (sources checked). |
| 3.6 | med | One scope per downloaded file | Applied: device-side scope links; the server `downloads` table drops its scope columns; free-space check. |
| 3.7 | med | Absolute paths, backed-up index and copied device ids | Applied: relative names, database and session in the backup-excluded folder, new device id per sign-in, Android `dataExtractionRules`. |
| 3.8 | med | Revoke doesn't sign out; SIGNED_OUT wipes downloads | Applied (with 2.4): wipe only on explicit sign-out or `device_revoked`. |
| 3.9 | med | Playback-state rule undefined for a device that is still playing | Applied (with 1.5): `is_playing`, `position_at`, detached mode, mobile write cadence, two-device test. |
| 3.10 | med | FLAC over cellular has no guard | Applied: per-device "Lossless over mobile data" setting (proposed default Ask), sizes and a monthly counter; OPEN 10 keeps the transcode question. |
| 3.11 | med | 1b depends on Area B pieces; estimates not credible | Applied: 1b takes natural order, the window planner, the contexts route and the drills; H1 before Area B's mobile work; ranges; Apple fee triggered by 1b. |
| 3.12 | med | TestFlight reach and a placeholder bundle id | Applied: id frozen as `app.tunehold.mobile`; TestFlight internal through App Store Connect users; 60-day rebuild; OPEN 1, 3 and 6 updated. |
| 3.13 | low | Cover URLs in the mirror expire after 48 h | Applied: `coverId` only, local cover files, `GET /covers/urls`. |
| 3.14 | low | Device FKs and the `user_queue` limit | Applied (duplicates of 1.13 and 1.5). |
