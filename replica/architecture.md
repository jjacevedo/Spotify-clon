# Architecture: Tunehold (a rebuild of the original's core features)

Final, 2026-10-04. `/replica-architect` phase. Inputs: `recon.md` (S01–S27, F01–F12, data model), `features.csv`, `fixes.md` (sections 5 and 7), `deferred.md`, `brand.md`, `design/tokens.json`, `launch/landing.md`, and the stack chosen by the judge pass over three proposals (Proposal 1 "managed default" as the base, with grafts from the other two).

**Scope.** Personal use by the founder and a few friends. Accounts are by invite. No payments, plans, pricing, legal workflows, store listings or sharing between accounts (`deferred.md`). An admin-set storage limit per user replaces plans. Web, iOS and Android from the start.

**In one line.** A pnpm/Turborepo TypeScript monorepo. Next.js on Vercel Hobby serves the landing page, the web app and a REST API. An Expo SDK 58 app covers iOS and Android. Supabase Free provides Postgres and Auth. Audio goes in a private Backblaze B2 bucket and moves only through presigned URLs, so no audio byte ever passes through Vercel.

All costs and durations in this document are **estimates**. Sources are listed at the end.

---

## Stack

| layer | choice | why |
| --- | --- | --- |
| monorepo | pnpm workspaces + Turborepo; TypeScript `strict` everywhere; Node 22 LTS | One install, one typecheck and one CI. Web and mobile share the API contract, the queue/shuffle engine and the tokens. |
| web app | Next.js (current stable, App Router) + React, one Vercel project | The landing page, app, REST API and sweep route ship in one deploy on one domain. |
| web UI | Tailwind CSS v4 themed from `replica/design/tokens.json`; Radix UI primitives; TanStack Virtual; dnd-kit | Tokens stay the single source. Radix provides keyboard and ARIA behaviour (AA, constraint T7). Virtualised lists handle 50k rows. dnd-kit handles drag reorder. |
| mobile app | Expo SDK 58 + expo-router, EAS development builds; StyleSheet with a theme from `packages/tokens`; FlashList; expo-image (`cacheKey` = cover id) | This was the founder's choice. Background audio needs config plugins, so Expo Go won't do. Pin SDK 58 when it goes stable (npm `next` was 58.0.3 and `latest` 57.0.26 on 2026-10-04). |
| API | Next.js Route Handlers under `/api/v1`, REST + JSON; zod schemas and a typed fetch client in `packages/contract` | One API for both clients, validated at the edge (constraint T2). |
| client data | TanStack Query on web and mobile (persisted on mobile) | Caching, retries and optimistic favorites and reorders, without custom plumbing. |
| database | Supabase Postgres, Free plan, two projects (dev, prod), with `pg_trgm` and `unaccent`. Neon Free is the documented swap. | $0. An estimated 40–120 MB against the 500 MB cap. |
| ORM + migrations | Drizzle ORM for typed queries; plain-SQL migrations in `packages/db/migrations` applied by `drizzle-kit migrate`; postgres.js through the Supavisor transaction pooler (port 6543, `prepare: false`) | Typed SQL that stays close to `schema.sql`. The pooler suits serverless functions. |
| access rules | **Data-layer checks**: owner-scoped repository functions take `ctx.userId` from the verified JWT. Backstops: RLS enabled with no policies, the Data API switched off, composite owner foreign keys, and a test suite that calls every route as a second user. | There is one path to the data, so there is one authorisation point. The backstops catch a leaked key or a missed owner filter. |
| auth | Supabase Auth (email + password), sign-ups disabled. The admin creates invites with `auth.admin.generateLink`. Web uses cookies (`@supabase/ssr`). Mobile sends a Bearer token, verified with `getClaims` (asymmetric JWT signing keys on). | Managed, free, and invite-only out of the box. |
| email | None in v1: the admin shares invite and reset links by chat. Resend Free becomes Supabase's custom SMTP once a domain exists. | Supabase's default SMTP only reaches the project's team members. |
| payments | **Deferred, see `deferred.md`.** | Personal use. An admin-set storage limit replaces plans. |
| files | Backblaze B2 private bucket (us-east) through the S3-compatible API, with presigned PUT and GET. Cloudflare R2 is a swap through env vars in `packages/storage`. | Storage dominates the cost: about $2.3/month for 343 GB on B2 vs about $5.0 on R2. Egress stays inside B2's free 3× allowance. Each user has their own copies, with no cross-user deduplication. |
| upload (web) | `@uppy/core` + `@uppy/aws-s3` used headless, with every signature from our API. A single PUT under 32 MB, multipart with 16 MB parts above that. MD5 per file with `hash-wasm` in a Web Worker. Folders are read with `webkitGetAsEntry`; on Chromium, `showDirectoryPicker` keeps the folder handle in IndexedDB. | Resumable S3 multipart without writing the protocol ourselves. |
| upload (mobile) | `expo-file-system`: `File.pickFileAsync` / `Directory.pickDirectoryAsync`, `file.info({ md5: true })`, `file.createUploadTask(url, { httpMethod: 'PUT', sessionType: 'background' })`. Always a single PUT. | First-party. Uploads use a background URLSession on iOS, and the MD5 is computed natively for large FLAC files. |
| tags + covers | `music-metadata` 12 + `@tokenizer/s3` range reads, `file-type` magic-byte sniffing, `sharp` for 600/300 px WebP covers, in a Node route or job on Vercel | Reads only the header bytes, MP4 tails included. Full Node runtime with no per-request CPU cap. One code path for web and mobile uploads. |
| jobs | A Postgres `jobs` table (`FOR UPDATE SKIP LOCKED`), run inline through `next/server` `after()`. A **GitHub Actions** schedule calls the sweep route hourly and takes a nightly `pg_dump` into a B2 backups bucket. The Vercel daily cron is a second trigger. | Hobby cron runs only once a day. Supabase Free has no usable backups and pauses after a week idle. Actions minutes are free (see Costs for the private-repo budget). |
| transcoding | None in v1: originals are streamed. Later and optional: `workers/transcode` (Node + ffmpeg) claiming jobs from Postgres. | MP3, AAC, FLAC and WAV play natively on every target. The stored original is never touched. |
| web playback | Own engine on `HTMLAudioElement` (current track plus a preloaded next one). Media Session API. A Zustand store driven by `packages/player-core`. `PlayerProvider` in the root `(app)` layout. On iOS Safari, a single element whose `src` is swapped on `ended` (to verify). | No dependency, and navigation never stops playback (constraint T5). iOS can block `play()` on a second element while the screen is locked. |
| mobile playback | `expo-audio` 58 `AudioPlaylist` with a rolling window (current + 2–4 next) fed by `player-core`; `setActiveForLockScreen` with `showNextTrack` / `showPreviousTrack`; the `enableBackgroundPlayback` plugin; `interruptionMode: 'doNotMix'`. Fallback: an SDK 57 single `AudioPlayer` with manual advance. | First-party, and lock-screen next/previous with playlists ships in expo-audio 58. `react-native-track-player` v5 is not a ready fallback: npm `latest` is 4.1.2, and v5 is alpha nightlies only (the last one is dated 2025-09-24). |
| queue / shuffle / resume | `packages/player-core`: a pure-TS state machine. The user queue plays before the context. F2 stop-at-end. Repeat off/all/one. Once-per-cycle shuffle by the keyed hash `md5(seed:memberId)`. One `playback_state` row per user, with a version column. | Satisfies F4: the shuffle state is three values, survives device switches and edits, and the same order is computed in SQL (online) and on the device (offline). |
| streaming URLs | Batched presigned B2 GETs (`/tracks/stream-urls?ids=`) with a 12 h TTL, re-signed and seeked back on any 403 or playback error. Covers are signed per UTC day, so their URLs stay stable and cacheable. | Audio is never public (constraint T3), and Vercel never proxies audio. |
| offline (mobile) | `File.createDownloadTask` into `Paths.document/tunehold/audio`, verified by size and MD5, then registered per device. `expo-sqlite` holds the offline index, a catalog mirror (from `GET /sync`) and the play-event outbox. Tombstones are applied on each reconnect. A local backup-exclude module on iOS, `android.allowBackup=false`, Wi-Fi-only downloads by default. | Satisfies F5: downloads aren't purgeable and are verified, the app is browsable in airplane mode, and copies are removed at the next connection. |
| search | `pg_trgm` + `unaccent` over generated `search_text` columns with GIN indexes, always filtered by `owner_id` | Covers F06's accent, case and partial-word cases with no search vendor. |
| landing page | `apps/web/app/(marketing)/page.tsx` at `/`, `force-static`, server components only | Same host and domain. It is the first code task. |
| export | Route handlers streaming M3U8 (zipped), CSV and history CSV | The export part of F7. The outputs are small, so no job is needed. |
| hosting | Vercel Hobby, functions in `iad1`, next to Supabase `us-east-1` and B2 us-east | $0. Hobby is for "personal, non-commercial" use, which matches `deferred.md`. |
| mobile builds | EAS Build Free. Android: internal-distribution APK. iOS: TestFlight internal testing once the Apple Developer Program is paid. | $0 until iOS distribution is worth paying for. EAS cloud builds need no Mac. |
| testing + CI | Vitest (packages, repositories, second-user suite), Playwright (web e2e, Chromium at `/opt/pw-browsers`), GitHub Actions (lint, typecheck, test, db tests, e2e, sweep gate), and an on-device checklist | Evidence over claims (process constraint 5). |
| Subsonic-compatible API | Not in v1. An optional, founder-triggered milestone (see "Subsonic and cars"). | The schema keeps stable per-user artist, album and track ids, so it stays cheap to add. |

### Dependencies (approved by this document)

Anything not listed needs a spec line or a BLOCKED report (process constraint 4).

| where | packages | why |
| --- | --- | --- |
| all | `typescript`, `turbo`, `eslint`, `prettier`, `vitest`, `zod` | Toolchain and validation. |
| `apps/web` | `next`, `react`, `react-dom`, `tailwindcss` (v4), `@radix-ui/react-*`, `@tanstack/react-query`, `@tanstack/react-virtual`, `@dnd-kit/core`, `@dnd-kit/sortable`, `zustand`, `@supabase/ssr`, `@supabase/supabase-js`, `@uppy/core`, `@uppy/aws-s3`, `hash-wasm`, `client-zip`, `@playwright/test` (dev) | Stack table. `client-zip` streams the playlists export zip. |
| `apps/mobile` | `expo`, `expo-router`, `expo-audio`, `expo-file-system`, `expo-sqlite`, `expo-image`, `expo-network` (Wi-Fi vs cellular), `expo-crypto` (`randomUUID`), `@shopify/flash-list`, `@supabase/supabase-js`, `@tanstack/react-query` + its persister, `eas-cli` (dev) | Stack table. The Supabase session is stored with `expo-sqlite`'s localStorage shim. |
| `packages/db` | `drizzle-orm`, `postgres`, `drizzle-kit` (dev), `supabase` CLI (dev, local stack for tests) | Database access and migrations. |
| `packages/storage` | `@aws-sdk/client-s3`, `@aws-sdk/s3-request-presigner` | S3 API against B2 or R2. |
| `packages/media` | `music-metadata`, `@tokenizer/s3`, `file-type`, `sharp` | Extraction, sniffing and covers. |
| `packages/player-core` | `js-md5`, `fractional-indexing` | The shuffle key must equal Postgres `md5()` on every client (Hermes has no WebAssembly, so `hash-wasm` won't run there). `fractional-indexing` gives order keys for playlist reorder. |

### Environment variables

Secrets live in Vercel, EAS and GitHub environments, never in the repo (constraint T9). Each package documents the variables it reads in its `.env.example`.

| name | where | what |
| --- | --- | --- |
| `DATABASE_URL` | web (server) | Supavisor **transaction** pooler, port 6543 |
| `DATABASE_URL_DIRECT` | CI, migrations, backup | Supavisor **session** pooler, port 5432. It is IPv4-reachable, unlike the direct host, which GitHub runners can't reach. |
| `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | web | Auth client |
| `SUPABASE_SECRET_KEY` | web (server only) | `auth.admin.*` for invites, recovery links and user purge |
| `EXPO_PUBLIC_SUPABASE_URL`, `EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY`, `EXPO_PUBLIC_API_BASE_URL` | mobile | Auth client and API origin |
| `S3_ENDPOINT`, `S3_REGION`, `S3_BUCKET`, `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY` | web (server) | B2 application key restricted to the audio bucket |
| `BACKUP_S3_BUCKET`, `BACKUP_S3_ACCESS_KEY_ID`, `BACKUP_S3_SECRET_ACCESS_KEY` | GitHub Actions only | A separate key that can only write to the backups bucket |
| `APP_ORIGIN` | web | e.g. `https://tunehold.vercel.app`. Used for invite links, the Origin check and bucket CORS. |
| `CRON_SECRET` | web, GitHub Actions | Bearer token for `/api/cron/sweep` |
| `ADMIN_EMAIL` | seed script | The founder's account, created with `role = 'admin'` |
| `MAX_FILE_BYTES` (default 1 GiB), `MULTIPART_THRESHOLD_BYTES` (32 MiB), `PART_SIZE_BYTES` (16 MiB), `UPLOAD_URL_TTL_SECONDS` (3600), `UPLOAD_SESSION_TTL_HOURS` (72), `STREAM_URL_TTL_SECONDS` (43200), `PURGE_GRACE_MINUTES` (10) | web (server) | Tunables. Defaults are shown in brackets. |

---

## Repo layout

```
tunehold (current repo root; replica/ and .claude/ stay as they are)
├─ package.json · pnpm-workspace.yaml · turbo.json · .npmrc · tsconfig.base.json · .env.example
├─ .github/workflows/
│  ├─ ci.yml                 lint · typecheck · test · db tests (postgres:17 service) · build · e2e · sweep gate
│  ├─ sweep.yml              hourly: curl -H "Authorization: Bearer $CRON_SECRET" $APP_ORIGIN/api/cron/sweep
│  └─ backup.yml             nightly 03:00 UTC: pg_dump -Fc via the session pooler → B2 backups bucket
├─ apps/
│  ├─ web/                                  Next.js App Router, one Vercel project (region iad1)
│  │  ├─ app/(marketing)/page.tsx           landing at "/" (force-static, light tokens). FIRST CODE TASK
│  │  ├─ app/(auth)/login/page.tsx          S03
│  │  ├─ app/(auth)/welcome/page.tsx        set a password after an invite link (replaces S02)
│  │  ├─ app/(auth)/reset/page.tsx          S04: set a new password after a recovery link
│  │  ├─ app/auth/confirm/route.ts          verifyOtp(token_hash, type) → session cookie → /welcome or /reset
│  │  ├─ app/(app)/layout.tsx               shell: sidebar or bottom nav, <PlayerProvider>, S12 bar, S13, S14
│  │  ├─ app/(app)/home · search · library · favorites · playlist/[id] · album/[id] · artist/[id]
│  │  │            · upload · history · settings · admin                (S05 S06 S07 S08 S09 S10 S11 S18 S21 + admin)
│  │  ├─ app/api/v1/**/route.ts             REST for web and mobile (see API)
│  │  ├─ app/api/cron/sweep/route.ts        CRON_SECRET-protected sweep
│  │  ├─ src/server/                        auth context, owner-scoped repositories, services, jobs runner
│  │  ├─ src/player/                        HTMLAudio engine + Media Session adapter over @tunehold/player-core
│  │  ├─ src/upload/                        Uppy wiring, MD5 worker, folder walker
│  │  ├─ src/marketing/status.ts            "Works today" / "In progress" flags for the landing cards
│  │  ├─ e2e/                               Playwright specs per flow (F01–F06, F10 by admin link)
│  │  └─ vercel.json                        region iad1, daily cron → /api/cron/sweep
│  └─ mobile/                               Expo SDK 58 app (expo-router, EAS)
│     ├─ app/(tabs)/home · search · library · upload ; app/player.tsx · queue.tsx
│     │   · playlist/[id].tsx · album/[id].tsx · artist/[id].tsx · favorites.tsx · downloads.tsx
│     │   · settings.tsx · login.tsx
│     ├─ src/player/                        expo-audio adapter: rolling window, lock screen, local-first sources
│     ├─ src/offline/                       download tasks, expo-sqlite schema (mirror, index, outbox), sync, tombstones
│     ├─ src/upload/                        pick files or a folder, native MD5, background upload tasks
│     ├─ modules/backup-exclude/            local Expo module: iOS isExcludedFromBackup on the audio folder
│     ├─ app.config.ts                      expo-audio plugin { enableBackgroundPlayback: true }; android.allowBackup=false;
│     │                                     bundle/package id com.tunehold.app (placeholder until the domain decision)
│     └─ eas.json                           development · preview (Android APK, internal) · testflight
├─ packages/
│  ├─ contract/      zod schemas for every /api/v1 route, error codes, typed fetch client
│  ├─ db/            Drizzle table definitions, migrations/0000_init.sql (= replica/schema.sql), seed.ts, repository tests
│  ├─ player-core/   queue, repeat, F2 end rule, once-per-cycle shuffle, PlaybackState reducer, rolling-window planner
│  ├─ media/         extraction, sniffing, covers, name keys, path and filename heuristics, M3U8/CSV writers
│  ├─ storage/       S3 client (B2 default, R2 by env): presign PUT/GET, multipart, head, range read, delete all versions
│  ├─ tokens/        build script: tokens.json → Tailwind v4 @theme CSS (web) + RN theme object (mobile)
│  └─ config/        tsconfig (strict), eslint and prettier presets
└─ workers/transcode/   LATER, optional: Node + ffmpeg container claiming transcode jobs (not created in v1)
```

Package names are `@tunehold/<name>`. App identifiers use `tunehold`, never the original's name (constraint 2). The deploy gate runs `sweep.py` on `apps/web` (including `public/`), `apps/mobile` and `packages`, and each run must exit 0.

---

## Schema

**Tables: 16. Access rules: data-layer checks** (owner-scoped repositories), with RLS enabled and no policies as a backstop. The full SQL is in [`replica/schema.sql`](schema.sql), which becomes migration `0000_init.sql`.

**Validation status: not executed.** This session had no shell and no Postgres. The first task that adds `packages/db` runs `psql -v ON_ERROR_STOP=1 --single-transaction -f replica/schema.sql` against a throwaway Postgres 17 and fixes any error before the slice starts.

| table | owner column | what it holds | notes |
| --- | --- | --- | --- |
| `profiles` | `id` (= auth user) | role, status, storage limit, `used_bytes`, `reserved_bytes`, settings | Holds the per-user storage limit and usage. FK to `auth.users` `on delete restrict`, added only on Supabase. |
| `invites` | `profile_id` | who invited whom, link regenerations, acceptance | |
| `devices` | `owner_id` | one row per install or browser; cellular-download switch; remote revoke | The id is generated on the device, so registering it is idempotent. |
| `covers` | `owner_id` | one row per distinct image per user; 600 and 300 px WebP keys | Deduplicated by sha256 within a user. |
| `artists` | `owner_id` | per-user artists, `name_key` for grouping, `search_text` | **Tables, not views:** stable ids, one row for cover and year, grouping decided once at ingest. |
| `albums` | `owner_id` | per-user albums keyed `(owner, album artist, title_key)` | `unique nulls not distinct`, because the album artist can be unknown. |
| `tracks` | `owner_id` | one uploaded file: immutable object key, size, MD5, sniffed MIME, audio properties, effective tags, raw tags, play count, status | `unique (owner_id, content_md5)` among rows that aren't deleted. Status values: `processing`, `ready`, `failed`, `disabled`, `deleted`. |
| `upload_sessions` | `owner_id` | one file in flight: mode, multipart id, part MD5s, reserved bytes, expiry | One live session per file per user (partial unique index on the MD5). |
| `jobs` | `owner_id` (nullable) | the Postgres queue, with a `dedupe_key` | Claimed with `SKIP LOCKED`. |
| `playlists` | `owner_id` | name, description, kind (`manual`, `smart` + `rules`), custom cover | |
| `playlist_items` | `owner_id` | track in a playlist, ordered by a fractional `sort_key` (`COLLATE "C"`) | Reorder is one row update. `unique (playlist_id, sort_key)`. |
| `favorites` | `owner_id` | the recon's Like | Append-only (unfavoriting writes a tombstone). |
| `play_events` | `owner_id` | listening history: client UUID, UTC time, IANA zone, `ms_played`, counted flag, title snapshot | Append-only and idempotent. |
| `playback_state` | `owner_id` (PK) | context, cursor, current item, position, user queue, shuffle `{seed, cycle, last_key}`, repeat, version | See PlaybackState below. |
| `downloads` | `owner_id` | verified copies per device per track, plus the scope that put each one there | |
| `tombstones` | `owner_id` | hard deletes for offline devices | Kept 180 days. |

No money, plan, entitlement or report tables. A `track_variants` table (for transcoded copies) and an `app_passwords` table (for Subsonic) are left for their optional milestones.

**Decisions inside the schema:**
- **Composite owner foreign keys.** Wherever a request names another row by id (playlist item → track, favorite → track, download → track and device, play event → track, playback state → current track, track → album/artist/cover), the child carries `owner_id`, and the FK is on `(id, owner_id)`. A cross-user id fails in Postgres even if a repository forgets its filter. Nullable links use `ON DELETE SET NULL (column)` (Postgres 15+). Drizzle can't express that, so migrations are hand-written SQL and `drizzle-kit push` is never used.
- **`on delete` rules.** Deleting a profile cascades everything. A track's hard delete cascades its playlist items, favorites and downloads, and sets `play_events.track_id` to null (history keeps its snapshot). An artist is `restrict`ed while albums use it, because `library_cleanup` removes empty albums first.
- **Search.** `search_text` is generated as `lower(unaccent(...))`, using an IMMUTABLE wrapper so it can be indexed. Each GIN trigram index covers all users and is always combined with `owner_id = $1`. That is fine for a handful of users. At a public launch, revisit with `btree_gin` composite indexes.
- **Times.** Every column is `timestamptz` in UTC. `play_events.client_tz` (IANA) is the only local-time data, used only for history.
- **`updated_at` is the sync cursor** for the offline mirror, kept current by triggers. Append-only tables (`favorites`, `play_events`, `tombstones`) have `created_at` only.

### Key queries (the repository layer owns them; listed here so the backend and the tests agree)

```sql
-- Storage limit, reserve (one row lock serialises a user's concurrent batches; the
-- WHERE clause is re-checked after the lock wait). No row back = 'storage_full'.
update profiles
   set reserved_bytes = reserved_bytes + $size
 where id = $uid and status = 'active'
   and used_bytes + reserved_bytes + $size <= storage_limit_bytes
returning used_bytes, reserved_bytes, storage_limit_bytes;

-- Storage limit, settle at /complete (same transaction as the tracks insert)
update profiles
   set reserved_bytes = reserved_bytes - $reserved, used_bytes = used_bytes + $size
 where id = $uid;

-- Once-per-cycle shuffle: next N of the whole library (memberId = track id; for a
-- playlist context memberId = playlist item id, so duplicates each get a key)
select t.id, md5($seed || ':' || t.id::text) collate "C" as k
  from tracks t
 where t.owner_id = $uid and t.status = 'ready'
   and ($last_key::text is null or md5($seed || ':' || t.id::text) collate "C" > $last_key)
 order by k
 limit $n;

-- Job claim
update jobs set status = 'running', locked_at = now(), locked_by = $worker, attempts = attempts + 1
 where id in (select id from jobs where status = 'queued' and run_after <= now()
               order by run_after limit $n for update skip locked)
returning *;
```

### PlaybackState (the spec `fixes.md` asks for before F4)

- **Members.** A context has an ordered set of members: album tracks by disc and track number; playlist items by `sort_key`; favorites by date added; artist tracks by album year, then disc and track; the library by the chosen sort; search results as a frozen id list (at most 1000). Each member exposes an ascending string key. In natural order, `context_cursor` stores the current member's key, and "next" is the first member with a greater key. Edits mid-play don't break it: added members fall where their key says, and removed ones are simply not found.
- **User queue.** "Play next" puts an entry at the front of `user_queue`; "Add to queue" puts it at the back. Entries play before the context resumes and are removed as they start. They don't move the context cursor or the shuffle state.
- **Shuffle (F4).** Turning shuffle on draws a random 32-hex `seed`, with `cycle = 0` and `last_key = null`. The order is `md5(seed + ':' + memberId)`, ascending, compared bytewise. "Next" is the smallest key above `last_key`. When none is left, the cycle ends. With repeat **all**, `cycle + 1` starts with a new seed. With repeat **off**, the context ends (`ended = true`, F2). So no member repeats inside a cycle, and members added mid-cycle play this cycle or the next. "Reshuffle" means a new seed with `last_key = null`. If a new cycle's first member equals the last one played, `player-core` skips it to the end of that cycle. The web and online mobile clients get "next N" from `GET /contexts/:type/:id/tracks?order=shuffle`, computed in SQL. Offline, the device sorts the keys of its mirror once per seed (about 3 MB for 50k members) and binary-searches `last_key`. `js-md5` and Postgres `md5()` must give the same hex: Vitest checks this against fixed vectors.
- **Repeat one** replays the current track. **Autoplay** (`profiles.settings.autoplay`, default `false`) only acts after `ended`, and draws only from the user's own ready tracks (F2).
- **Sync.** Clients `PUT` the whole state with `If-Match: <version>` every ~15 s while playing, and on pause, track change, queue edit or toggle. A version mismatch gets `409 version_conflict` with the current state. Rule: the device the user is touching wins. A client that receives a 409 because of its own explicit action re-PUTs on top of the returned version. A background periodic PUT adopts the server state instead. Resume across devices (S12 on open): `GET /playback-state`, then the player starts paused at `position_ms`.

---

## API

### Conventions

- **Base** `/api/v1`, JSON, validated with the zod schema from `packages/contract` (both ways in tests). Ids are UUIDs.
- **Auth.** Either the web session cookie (`@supabase/ssr`) or `Authorization: Bearer <access token>` (mobile). The server calls `supabase.auth.getClaims()`, then loads the profile. Only `status = 'active'` passes, except for the invite-acceptance routes, which also accept `invited`. Cookie-authenticated `POST/PUT/PATCH/DELETE` requests must send `Content-Type: application/json` and an `Origin` equal to `APP_ORIGIN` (CSRF guard).
- **Who:** `public`, `invited` (an invite session that hasn't accepted yet), `member` (any active user, own data only), `admin` (role `admin`), `cron` (`Authorization: Bearer $CRON_SECRET`).
- **Ownership.** Another user's resource answers `404 not_found`, never 403, so nothing leaks its existence.
- **Errors.** `{ "error": { "code": string, "message": string, "details"?: unknown } }`. Codes: `unauthorized` 401, `forbidden` 403, `not_found` 404, `validation_failed` 400, `conflict` 409, `version_conflict` 409, `duplicates` 409, `storage_full` 409, `in_progress` 409, `unsupported_format` 415, `file_too_large` 413, `integrity_failed` 422, `not_ready` 409, `gone` 410, `internal` 500. Messages are plain sentences in the brand voice. The UI copy comes from `brand.md`.
- **Lists** use cursor pagination: `?cursor=&limit=` (default 50, max 200), with the response `{ items, nextCursor }`. The cursor is an opaque base64 of `(sortKey, id)`.
- **Request caps.** Batch upload ≤ 500 files. `stream-urls` ≤ 50 ids. Playlist add ≤ 500 tracks. Play events ≤ 500 per post. Sync pages ≤ 1000 rows. Bodies stay well under Vercel's 4.5 MB limit, because audio and images never go through the API.

### Contract shapes (zod in `packages/contract`; summarised)

```ts
type TrackDto = {
  id: string; status: 'processing' | 'ready' | 'failed' | 'disabled';
  title: string; artistName: string | null; albumTitle: string | null; albumArtistName: string | null;
  albumId: string | null; artistId: string | null; trackNo: number | null; discNo: number | null;
  year: number | null; genre: string | null; durationMs: number | null; codec: string | null;
  lossless: boolean | null; sampleRateHz: number | null; bitDepth: number | null;
  sizeBytes: number; ext: string; mime: string; contentMd5: string;
  coverId: string | null; coverUrl300: string | null;            // day-bucketed signed URL
  isFavorite: boolean; playCount: number; lastPlayedAt: string | null;
  addedAt: string; updatedAt: string; statusReason: string | null;
};

type UploadBatchRequest = {
  batchId: string; client: 'web' | 'ios' | 'android';
  files: Array<{ clientFileId: string; kind: 'audio' | 'cover'; name: string;
                 relativePath?: string; size: number; md5: string /* hex */; mime?: string }>; // ≤ 500
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

type PlaybackStateDto = {
  version: number; deviceId: string | null;
  context: { type: 'album' | 'artist' | 'playlist' | 'favorites' | 'library' | 'search' | 'queue';
             id: string | null; sort?: string; trackIds?: string[] } | null;
  contextCursor: string | null; currentTrackId: string | null; currentItemId: string | null;
  positionMs: number; userQueue: Array<{ entryId: string; trackId: string }>;
  shuffle: { on: boolean; seed: string | null; cycle: number; lastKey: string | null };
  repeat: 'off' | 'all' | 'one'; ended: boolean; updatedAt: string;
};

type SyncPage = {
  cursor: string; hasMore: boolean; fullResync: boolean; wipe: boolean;
  tracks: TrackDto[]; albums: AlbumDto[]; artists: ArtistDto[]; playlists: PlaylistDto[];
  playlistItems: Array<{ id: string; playlistId: string; trackId: string; sortKey: string; addedAt: string }>;
  favorites: Array<{ trackId: string; createdAt: string }>;
  tombstones: Array<{ entity: 'track' | 'album' | 'artist' | 'playlist' | 'playlist_item' | 'favorite';
                      entityId: string; at: string }>;
};

type ManifestItem = { trackId: string; sizeBytes: number; md5: string; ext: string; mime: string;
                      url: string; urlExpiresAt: string; coverId: string | null; coverUrl600: string | null };
```

### Routes by flow

**63 route handlers**: 61 under `/api/v1`, plus `/api/cron/sweep` and `/auth/confirm`. Pages (the landing page and app screens) aren't counted.

#### F01: upload (S18) and ingest

| method path | does | who | input | output | flow |
| --- | --- | --- | --- | --- | --- |
| POST `/api/v1/uploads/batch` | Per file, in order: rejects bad extensions and sizes; finds duplicates (an existing track with the same MD5 → `duplicate`) and live sessions (→ `resume`); otherwise reserves the bytes atomically and creates a session (→ `upload`), or answers `storage_full`. Cover sidecars get a session with no reservation. | member | `UploadBatchRequest` | `UploadBatchResult` | F01, F6 |
| GET `/api/v1/uploads/:id` | Session status. For `single`: a fresh presigned PUT URL (TTL 1 h; Content-Type and Content-MD5 fixed in the signature). For `multipart`: the parts uploaded so far (ListParts), for resume. Pushes `expires_at` 72 h forward. | member | — | `{ session, upload?: { url, headers, expiresAt }, uploadedParts?: [{ partNumber, etag, size }] }` | F01 |
| POST `/api/v1/uploads/:id/parts` | Creates the S3 multipart upload on the first call (session row locked), then signs PUT URLs for the requested parts (≤ 100 per call) and stores their MD5s | member | `{ parts: [{ partNumber, md5 }] }` | `{ parts: [{ partNumber, url, headers }], expiresAt }` | F01 |
| POST `/api/v1/uploads/:id/complete` | Idempotent. Guard `pending → completing` (an already completed session returns its track; one that is `completing` returns `409 in_progress`). Completes the multipart upload. Checks HeadObject size against the declared size, the ETag(s) against the MD5s, and the first 4 KB with `file-type`. In one transaction: inserts the `tracks` row (`processing`), settles the reservation and enqueues `extract` (deduplicated). Then `after()` runs the job. Integrity failure: deletes the object, releases the bytes, `422 integrity_failed`. Unsupported real type: `415`. A track with the same MD5 that appeared meanwhile: deletes the object and answers `duplicate`. | member | `{ parts?: [{ partNumber, etag }] }` | `{ track: TrackDto }` | F01, F6 |
| DELETE `/api/v1/uploads/:id` | Aborts: AbortMultipartUpload or deletes the partial object, releases the reservation once, status `aborted` | member | — | 204 | F01 |
| GET `/api/v1/uploads` | Sessions for S18 progress across reloads and devices | member | `?batchId=&status=&cursor=` | `Page<UploadSessionDto>` | F01 |
| POST `/api/v1/tracks/:id/reprocess` | Re-runs extraction for a `failed` track, or re-reads tags while keeping the fields the user edited | member | — | `{ track }` | F01 |

#### F01 / F02: library (S05, S07, S10, S11, S19)

| method path | does | who | input | output | flow |
| --- | --- | --- | --- | --- | --- |
| GET `/api/v1/library/tracks` | Tracks list (ready and processing; failed on request) | member | `?sort=added\|title\|artist\|album&dir=&status=&q=&cursor=&limit=` | `Page<TrackDto>` | F01, F02 |
| GET `/api/v1/library/albums` | Albums with cover, artist, year and track count | member | `?sort=added\|title\|artist\|year&q=&cursor=` | `Page<AlbumDto>` | F01 |
| GET `/api/v1/library/artists` | Artists with album and track counts | member | `?q=&cursor=` | `Page<ArtistDto>` | F01 |
| GET `/api/v1/tracks/:id` | One track | member | — | `TrackDto` | F02 |
| PATCH `/api/v1/tracks/:id` | Edits tags (S19): re-groups the album and artist, records `user_edited_fields`. The file is untouched. | member | `{ title?, artistName?, albumTitle?, albumArtistName?, trackNo?, discNo?, year?, genre?, coverUploadKey? \| removeCover? }` | `TrackDto` | F01 |
| DELETE `/api/v1/tracks/:id` | Soft delete (`deleted`), then a `purge_track` job after `PURGE_GRACE_MINUTES`. The bytes come back at purge. | member | — | 204 | F01 |
| POST `/api/v1/tracks/bulk-delete` | Same for ≤ 500 ids | member | `{ ids: string[] }` | `{ deleted: number }` | F01 |
| GET `/api/v1/albums/:id` | Album header and tracks (disc, track number) | member | — | `{ album, tracks: TrackDto[] }` | F01, F02 |
| PATCH `/api/v1/albums/:id` | Bulk tag edit for every track of the album (title, artist, year, cover) | member | `{ title?, artistName?, year?, coverUploadKey? }` | `{ album }` | F01 |
| GET `/api/v1/artists/:id` | Artist: albums, most-played tracks (personal counts), loose tracks | member | — | `{ artist, albums, topTracks, otherTracks }` | F02 |
| GET `/api/v1/home` | S05: quick picks (6–8 recent contexts), recently played, recently added albums. Later: most played, not played in a while. Empty library: `{ empty: true }`. | member | `?tz=` | `{ quickPicks, shelves: [...] }` | F02 |
| POST `/api/v1/covers/uploads` | A presigned PUT for a user-chosen image (≤ 10 MB, JPEG/PNG/WebP) at `u/{uid}/in/…`; then PATCH a track, album or playlist with `coverUploadKey` | member | `{ size, mime, md5 }` | `{ coverUploadKey, url, headers, expiresAt }` | F01, F03 |

#### F02 / F04: streaming, queue and playback state (S12, S13, S14)

| method path | does | who | input | output | flow |
| --- | --- | --- | --- | --- | --- |
| GET `/api/v1/tracks/stream-urls` | Presigned GETs (TTL 12 h, `response-content-type` set) for ready tracks the user owns. Range requests go straight to B2. | member | `?ids=a,b,c` (≤ 50) | `{ urls: [{ trackId, url, expiresAt, mime, sizeBytes }], errors: [{ trackId, code: 'not_found'\|'not_ready'\|'unavailable' }] }` | F02 |
| GET `/api/v1/playback-state` | The user's playback state (creates it at version 1 if absent) | member | — | `PlaybackStateDto` | F02, F04 |
| PUT `/api/v1/playback-state` | Replaces it if `If-Match` equals the version, then version + 1 | member | header `If-Match`, `PlaybackStateDto` without version | `{ version }` or `409 version_conflict` + current state | F02, F04 |
| GET `/api/v1/contexts/:type/:id/tracks` | Ordered members of a context: natural order after a cursor, or shuffle order after `lastKey` for a seed (SQL). `id` = `all` for the library and favorites. | member | `?order=natural\|shuffle&sort=&after=&seed=&lastKey=&limit=` (≤ 200) | `{ members: [{ key, trackId, itemId? }], end: boolean }` | F02, F04 |
| POST `/api/v1/play-events` | Idempotent batch insert (`ON CONFLICT (id) DO NOTHING`). For newly inserted counted events, in the same transaction: `play_count + 1` and `last_played_at`. The server fills the title snapshot from the owner's track. A foreign track id is rejected. | member | `{ events: [{ id, trackId, deviceId, playedAt, msPlayed, contextType?, contextId?, clientTz }] }` (≤ 500) | `{ accepted, duplicates }` | F02, F8 |
| GET `/api/v1/history` | History (should): play events newest first, shown in the event's own zone | member | `?from=&to=&cursor=` | `Page<PlayEventDto>` | F8 |

#### F03: playlists (S09, S16, S17); F05: favorites (S08)

| method path | does | who | input | output | flow |
| --- | --- | --- | --- | --- | --- |
| GET `/api/v1/playlists` | The user's playlists with counts, durations and mosaic covers | member | `?q=&cursor=` | `Page<PlaylistDto>` | F03 |
| POST `/api/v1/playlists` | Creates one (manual, or smart with rules) | member | `{ name, description?, kind?, rules? }` | `PlaylistDto` | F03 |
| GET `/api/v1/playlists/:id` | Header: name, description, cover or mosaic, count, duration | member | — | `PlaylistDto` | F03 |
| PATCH `/api/v1/playlists/:id` | Rename, describe, set or remove the cover, edit rules | member | `{ name?, description?, coverUploadKey? \| removeCover?, rules? }` | `PlaylistDto` | F03 |
| DELETE `/api/v1/playlists/:id` | Deletes it, with a tombstone | member | — | 204 | F03 |
| GET `/api/v1/playlists/:id/items` | Items in `sort_key` order (smart: computed from the rules). `q` searches inside the playlist (F8). | member | `?q=&cursor=&limit=` | `Page<{ itemId, sortKey, addedAt, track: TrackDto }>` | F03 |
| POST `/api/v1/playlists/:id/items` | Adds tracks after an item (or at the end). Key generation happens on the server. `onDuplicate: 'ask'` returns `409 duplicates` with the ids already present; `'skip'` or `'add'` resolves it. | member | `{ trackIds (≤ 500), afterItemId?: string \| null, onDuplicate?: 'ask'\|'skip'\|'add' }` | `{ items }` | F03 |
| PATCH `/api/v1/playlists/:id/items/:itemId` | Moves one item: the server reads the neighbours' keys and writes one new `sort_key`. On a unique-index clash it retries once with fresh neighbours. | member | `{ afterItemId: string \| null }` | `{ itemId, sortKey }` | F03 |
| POST `/api/v1/playlists/:id/items/remove` | Removes items, with tombstones | member | `{ itemIds }` | `{ removed }` | F03 |
| POST `/api/v1/playlists/import` | M3U/M3U8 import (should): matches each line by `relative_path`, then filename, then title and artist, within the user's library | member | `{ name, content }` (text ≤ 1 MB) | `{ playlistId, matched, unmatched: string[] }` | F6 |
| GET `/api/v1/favorites` | Favorited tracks, newest first | member | `?cursor=` | `Page<TrackDto>` | F05 |
| PUT `/api/v1/favorites/:trackId` | Favorite (idempotent) | member | — | 204 | F05 |
| DELETE `/api/v1/favorites/:trackId` | Unfavorite (idempotent; writes a tombstone; the undo toast calls PUT) | member | — | 204 | F05 |

#### F06: search (S06)

| method path | does | who | input | output | flow |
| --- | --- | --- | --- | --- | --- |
| GET `/api/v1/search` | Normalises the query (`search_norm`) and splits it into words. Every word must appear (`search_text LIKE '%w%'`, served by the trigram index). Ranking: title or name prefix > word start > substring > trigram similarity. Returns the top result plus the groups. One- and two-character queries use prefix matching only. | member | `?q=&types=tracks,albums,artists,playlists&limit=` (≤ 50 per type) | `{ top, tracks, albums, artists, playlists }` | F06 |

#### F07 / F5: offline downloads (S24, mobile)

| method path | does | who | input | output | flow |
| --- | --- | --- | --- | --- | --- |
| GET `/api/v1/downloads/manifest` | The files for one scope, with signed URLs (12 h) and covers. Ready tracks only. | member | `?scope=track\|album\|playlist\|favorites\|library&id=&cursor=&limit=` (≤ 500) | `Page<ManifestItem>` | F07 |
| PUT `/api/v1/devices/:id/downloads` | Registers copies the device has verified (size + MD5) | member | `{ items: [{ trackId, scopeType, scopeId?, sizeBytes }] }` | `{ registered }` | F07 |
| POST `/api/v1/devices/:id/downloads/remove` | Unregisters copies the device removed | member | `{ trackIds }` | `{ removed }` | F07 |
| GET `/api/v1/sync` | Offline mirror feed: rows changed since the cursor (`updated_at`, with a 120 s overlap; the client upserts idempotently), plus tombstones. `fullResync` if the cursor is older than tombstone retention. `wipe` if the device was revoked. Also stamps `devices.last_sync_at`. | member | `?cursor=&deviceId=` | `SyncPage` | F07, F5 |

#### F10 + admin: invites, limits, account (admin page, S03, S04, S21, S22)

| method path | does | who | input | output | flow |
| --- | --- | --- | --- | --- | --- |
| GET `/auth/confirm` | `verifyOtp({ token_hash, type })`, sets the session cookie, redirects: `invite` → `/welcome`, `recovery` → `/reset`, expired → `/login?link=expired` | public | `?token_hash=&type=invite\|recovery` | 303 | F10 |
| POST `/api/v1/admin/invites` | `auth.admin.generateLink({ type: 'invite', email })`, which creates the auth user. Inserts the profile (`invited`, with its limit) and the invite. Builds our own link `APP_ORIGIN/auth/confirm?token_hash=…&type=invite`. | admin | `{ email, storageLimitBytes }` | `{ inviteId, userId, link, expiresAt }` | F10 |
| POST `/api/v1/admin/invites/:id/link` | A new link for an unaccepted invite (links expire with the project's email OTP expiry) | admin | — | `{ link, expiresAt }` | F10 |
| DELETE `/api/v1/admin/invites/:id` | Revokes an unaccepted invite: deletes the profile, then the auth user | admin | — | 204 | F10 |
| GET `/api/v1/admin/users` | Usage only: email, name, status, limit, used, reserved, track count, last seen. **Never** anyone's library (privacy among friends). | admin | `?cursor=` | `Page<AdminUserDto>` | — |
| PATCH `/api/v1/admin/users/:id` | Sets the storage limit, or disables/enables the account (a Supabase ban plus profile status) | admin | `{ storageLimitBytes?, status?: 'active'\|'disabled' }` | `AdminUserDto` | — |
| POST `/api/v1/admin/users/:id/recovery-link` | Password reset by admin link until a domain and SMTP exist | admin | — | `{ link, expiresAt }` | F10 |
| GET `/api/v1/me` | Profile, usage (`used`, `reserved`, `limit`), settings | invited, member | — | `MeDto` | — |
| PATCH `/api/v1/me` | Display name, settings (`autoplay`) | member | `{ displayName?, settings? }` | `MeDto` | F12 |
| POST `/api/v1/me/activate` | After `/welcome` sets the password (`supabase.auth.updateUser`): `invited → active`, `invites.accepted_at` | invited | — | `MeDto` | F10 |
| DELETE `/api/v1/me` | Account deletion: `status = 'deleting'`, signs out everywhere, enqueues `purge_user` (OPEN 12) | member | `{ confirm: 'DELETE' }` | 202 | — |
| PUT `/api/v1/devices/:id` | Registers or updates this device (idempotent) | member | `{ name, platform, appVersion?, allowCellularDownloads? }` | `DeviceDto` | F07 |
| GET `/api/v1/devices` | Devices with download count and bytes | member | — | `DeviceDto[]` | F07 |
| DELETE `/api/v1/devices/:id` | Remote sign-out: `revoked_at`, deletes its `downloads` rows. At its next sync the device gets `wipe = true`. | member | — | 204 | F07 |

#### F7: export (S21 / account page)

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

| job | schedule or trigger | what it does |
| --- | --- | --- |
| `extract` | Enqueued by `/complete`; run by `after()` straight away; retried by the sweep (backoff 1 min, 10 min, 1 h, 6 h; 5 attempts) | `music-metadata` over `@tokenizer/s3` (range reads), effective tags with fallbacks (path, then filename), embedded cover → sha256 → `covers` (sharp WebP 600 and 300) → artist and album upsert → `ready`. Unparseable audio → `failed` with a reason (the file stays stored and visible in S18 with "Try again"). |
| `apply_sidecar_cover` | `/complete` of a `cover` session | For tracks of the same batch and folder that have no embedded art: sets their album's cover if empty. Order-independent: runs whether the audio or the image arrived first. |
| `regroup_batch` | When a batch has no live sessions left (or 10 min after its last activity) | Merges albums that the same folder split by track artist when `albumartist` was missing: one album, artist "Various Artists" if the artists differ. |
| `purge_track` | `DELETE /tracks/:id`, `run_after = now() + PURGE_GRACE_MINUTES` | Deletes every version of the object (B2 keeps versions). In one transaction: deletes the row (cascades), `used_bytes -= size`, writes a `track` tombstone. Then enqueues `library_cleanup`. |
| `purge_user` | `DELETE /me` or the admin's removal | Deletes every object under `u/{id}/`, then the profile (cascade), then the auth user. |
| `library_cleanup` | After purges and tag edits; hourly from the sweep | Deletes albums with no tracks, then artists with no albums and no tracks, then unreferenced covers and their objects, writing tombstones. |
| **sweep** (route) | GitHub Actions **hourly**; Vercel cron daily as a second trigger | 1) Requeues `running` jobs locked for more than 10 min. 2) Runs due jobs within the budget. 3) Expires sessions past `expires_at`: aborts multipart uploads, deletes orphan single objects, releases reservations. 4) Resets `completing` sessions untouched for more than 10 min back to `pending`. 5) Reconciles `used_bytes` and `reserved_bytes` from the source tables. 6) Prunes tombstones older than 180 days and finished jobs older than 30 days. Its database query also keeps Supabase Free from pausing. |
| **db backup** (workflow) | GitHub Actions nightly 03:00 UTC | `pg_dump -Fc` through the **session pooler** (the direct host is IPv6-only) into a separate B2 `tunehold-backups` bucket, with a lifecycle rule keeping 30 days. Restore drill: `pg_restore` into the dev project once per milestone. Audio isn't backed up: B2 is the primary copy, and users keep their originals (landing FAQ). |
| B2 lifecycle rules | Set once with the `b2` CLI | Audio bucket: "keep only the last version" (so deletes free space) and cancel unfinished large files after 7 days (a backstop for the sweep). |

---

## Audio pipeline (summary)

1. **Pick.**
   - Web: files, or a folder dropped or picked (`webkitGetAsEntry`; on Chromium, `showDirectoryPicker` with its handle in IndexedDB).
   - Mobile: `File.pickFileAsync({ multiple })` or `Directory.pickDirectoryAsync()`.
   - Accepted: `mp3`, `m4a`/`mp4`/`aac`, `flac`, `wav`, plus `cover.jpg`, `folder.jpg` and `front.jpg|png` sidecars.
2. **Fingerprint.** An MD5 per file: `hash-wasm` in a Web Worker on the web, `file.info({ md5: true })` on mobile. It is used only for duplicates inside the user's own library.
3. **Reserve.** `POST /uploads/batch` in chunks of ≤ 500, in walk order. It returns `upload`, `resume`, `duplicate`, `storage_full` or `unsupported` per file. "{done} of {total} added before your space filled up" falls out of the order.
4. **Transfer straight to B2.**
   - Web: Uppy runs 4 files in parallel. Under 32 MB: a single PUT whose URL is fetched just before it starts (`GET /uploads/:id`). From 32 MB: multipart, 16 MB parts signed in batches.
   - Mobile: a single PUT per file through a background upload task.
   - `Content-MD5` is sent (base64 of the MD5) on every PUT and part.
5. **Complete.** `POST /uploads/:id/complete` checks the size, the ETag or part ETags against the client MD5s, and sniffs the real type. In one transaction it inserts the track and settles the bytes, then enqueues extraction.
6. **Extract.** See the `extract` job. Covers are keyed per user by image hash, and grouping keys come from `packages/media`.
7. **Store.**
   - `u/{userId}/o/{trackId}.{ext}` is written once and never rewritten (F6).
   - Covers live at `u/{userId}/c/{sha256}-{600|300}.webp`.
   - Inbox images live at `u/{userId}/in/{sessionId}.{ext}`.
   - Later streaming copies would go to `u/{userId}/s/{trackId}.m4a`.
   - There is no cross-user deduplication: two users uploading the same file get two objects.

---

## The parts that bite

- **Resumable uploads.**
  - The browser can't keep `File` objects across a reload, so resuming means re-dropping the folder: duplicates come back as `duplicate`, and half-done multipart uploads come back as `resume` with their uploaded parts. On Chromium, the stored directory handle avoids re-picking.
  - Mobile background uploads survive suspension. Whether picked files and folders stay readable after an app restart is **to verify on device**; if not, the user re-picks and the duplicates are skipped.
  - Stale sessions expire after 72 h of inactivity and release their bytes. B2's unfinished-large-file rule is the backstop.
  - The first import of ~343 GB takes about 38 h at 20 Mbps upstream (estimate), so resume matters more than speed.
- **S3 compatibility.**
  - AWS SDK v3 sends CRC32 checksum headers by default since v3.729, and B2 rejects them. `packages/storage` sets `requestChecksumCalculation: 'WHEN_REQUIRED'` and `responseChecksumValidation: 'WHEN_REQUIRED'`, and strips `x-amz-checksum-mode` on GETs if B2 still rejects it.
  - CORS for browser PUTs (exposing `ETag`) is set with the `b2` CLI.
  - B2 keeps old versions unless the lifecycle rule says otherwise, so deletes remove every version.
- **Integrity (F6).**
  - Whether B2 enforces `Content-MD5`, and whether its single-PUT ETag equals the MD5, is **unconfirmed**. The web slice records both on the dev bucket.
  - If the ETag isn't the MD5, `extract` streams the object once and hashes it instead. Cost: B2 egress inside the free 3× allowance, and ≤ 300 s per file on Vercel for files up to ~1 GB.
- **Idempotency.**
  - `/complete` is guarded by the `pending → completing → completed` transition, and a retry returns the same track.
  - Play events use client UUIDs.
  - Jobs are enqueued with `dedupe_key` (`on conflict … do nothing`).
  - Favorites are PUT and DELETE.
  - Device registration is an upsert by client id.
  - The sweep's releases happen once, through status transitions.
- **Storage limit enforcement.**
  - It is one conditional `UPDATE … RETURNING` per file (see Key queries), so two tabs or devices can't both pass the check.
  - The hourly reconcile repairs drift.
  - The admin can set a limit below usage: nothing is deleted, everything keeps playing and downloading, and uploads are refused (brand string 9 without the plan wording).
- **Races.**
  - *Playlist reorder:* the server writes a fractional key; two moves into the same gap hit `unique (playlist_id, sort_key)`, and the loser retries once with fresh neighbours. The client updates optimistically and refetches on error.
  - *Queue edits on two devices:* `playback_state.version`, where the device being touched wins.
  - *The same file in two tabs:* the partial unique index on live sessions gives one session and one `resume`.
  - *A duplicate finishing first:* the unique index on tracks returns `duplicate` and the extra object is deleted.
  - *Concurrent job claims:* `SKIP LOCKED`.
- **Large libraries (50k tracks).**
  - Every list is virtualised (TanStack Virtual, FlashList) and every endpoint is cursor-paginated.
  - Whole-library shuffle and search run in SQL. No client ever downloads every row except the mobile mirror, which pages through `/sync` (~1,000 rows per page).
  - Storage estimate: ~120 MB for 75k tracks, inside the 500 MB Free cap. Watch `play_events` growth.
- **Tag edge cases.**
  - Files with only ID3v1; a missing `albumartist` (handled by `regroup_batch`); compilations and "Various Artists"; multi-disc albums (the disc comes from the tag or a `CD1`/`Disc 1` folder).
  - Track numbers written as "3/12"; odd text encodings; multi-artist credits (v1 groups by the first artist and keeps the full credit as display text); MP3 VBR without a Xing header (`duration_estimated = true`).
  - MP4 with `moov` at the end (range reads handle it); WAV with RIFF INFO only.
  - CUE + single-file FLAC images aren't split in v1. ALAC in `.m4a` doesn't play in Chrome or Firefox: it is flagged by codec, and the web player shows "plays on phones and Safari".
  - Fixture files for each case live in `packages/media` tests.
- **Gapless and background audio.**
  - *Android:* background playback stops after ~3 minutes unless `setActiveForLockScreen` is active (expo-audio typings), so the call is mandatory, together with the Media3 foreground service from the plugin.
  - *iOS:* `UIBackgroundModes audio` comes from the plugin; `interruptionMode: 'doNotMix'` is required for lock-screen controls.
  - *Rolling window:* JS refills the native playlist while the phone is locked. If that proves unreliable on a real device, fall back to the SDK 57 single player with manual advance.
  - *Gapless:* Media3 handles MP3 and AAC encoder delay; AVQueuePlayer and two HTML audio elements narrow the gap but don't promise sample-accurate playback. Accept near-gapless (gapless is a should), and test with a live album.
  - *Web on iOS Safari:* reuse one element (to verify) and hide the volume slider.
  - *Exit test for each platform:* 2 h of locked playback across album boundaries, on a real device.
- **Signed URL expiry vs long playback.**
  - Stream URLs last 12 h and are signed when a track enters the native window or the web preload. Any 403, `error` event or stalled load re-signs and seeks back to the current position.
  - Downloads re-sign when a paused task resumes after expiry.
  - Cover URLs use a signing date floored to the UTC day and a 48 h expiry. The URL is then identical all day, so browsers cache it, and mobile caches by `cacheKey = coverId`.
- **Offline cache integrity (F5).**
  - Each file goes to `….part`, is checked for size and MD5 (`file.info({ md5: true })`), then renamed and registered.
  - Files live in `Paths.document`, not the cache directory. iOS backs up Documents by default, so the local `backup-exclude` module sets `isExcludedFromBackup`; Android sets `allowBackup=false`.
  - Playback is local-first.
  - Tombstones and `deleted`/`disabled` rows remove files at the next sync; there is no check-in (accepted in `fixes.md`; the takedown check-in question is deferred with the legal work).
  - Signing out, or `wipe = true`, deletes every download.
  - Downloads are Wi-Fi only unless the device's cellular switch is on (`expo-network`).
- **Search over 50k tracks.**
  - Trigram GIN on normalised `search_text`; every word must match. Estimated well under 50 ms per user library (unmeasured: the slice records `EXPLAIN ANALYZE` on a 50k-row seed).
  - One- and two-character queries use prefix matching.
  - Recent searches are stored on the client only (no table).
- **Time zones.**
  - Everything is UTC. `play_events.client_tz` drives the history page and the history CSV only.
  - The "recently played" shelves take the viewer's current `?tz=`.
  - No scheduling, so daylight saving doesn't matter anywhere else.
- **Multi-tenancy and privacy among friends.**
  - Owner-scoped repositories, composite owner FKs, RLS deny-all, the Data API off, 404s for other users' ids, and a Vitest suite that calls every route as user B against user A's ids.
  - The admin sees usage, never libraries.
- **Account deletion.**
  - `purge_user` deletes the user's objects, then their rows, then the auth user.
  - The `profiles → auth.users` key is `on delete restrict`, so the dashboard can't orphan files.
  - Grace period and notice: OPEN 12 (the policy work is deferred).
- **Rate limits and file sizes.**
  - No rate limiter in v1 (personal scale, and Supabase Auth has its own limits). Per-request caps are listed under Conventions.
  - `MAX_FILE_BYTES` defaults to 1 GiB (B2's single-PUT ceiling is 5 GB). Covers are ≤ 10 MB.
  - Revisit both at any launch.
- **Email deliverability.** None in v1: links are shared by chat. Self-service reset (F10) waits for a domain and Resend.
- **Realtime.** None. Connect-style remote control is a could. Devices pick up the state on focus or open.
- **Platform limits.**
  - Vercel Hobby: functions max 300 s, request bodies 4.5 MB, cron once a day, personal non-commercial use only.
  - Supabase Free: pauses after a week idle (the hourly sweep counters this; to verify that pooled queries count as activity), and no usable backups (nightly `pg_dump`).
  - GitHub: scheduled workflows in public repos stop after 60 days with no repository activity, and private repos have a minutes budget (see Costs).
- **Monorepo React versions.** Expo SDK 58 pins a React version, so `apps/web` uses the same one. `.npmrc` uses `node-linker=hoisted` if Metro needs it; the scaffold task decides with a working dev build.

---

## Build order

Sizes follow `WORKFLOW.md`. Each milestone lists its screens, tables and routes.

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
- **Tables:** migration 0000 applied in full. Used: `profiles`, `invites`, `artists`, `albums`, `covers`, `tracks`, `upload_sessions`, `jobs`.
- **Routes:** `/auth/confirm`, `POST /admin/invites`, `GET /me`, `POST /me/activate`, `POST /uploads/batch` (single mode only), `GET /uploads/:id`, `POST /uploads/:id/complete`, `DELETE /uploads/:id`, `GET /library/tracks`, `GET /library/albums`, `GET /albums/:id`, `GET /tracks/stream-urls`, `/api/cron/sweep` (job retry, session expiry), plus `seed.ts` for the founder's admin account.
- **Done when:**
  - The founder, on the deployed URL, uploads one MP3 and one FLAC; both appear with tags and cover and play with seek.
  - The second-user suite is green for these routes.
  - The B2 findings are recorded in the spec: Content-MD5 enforced? ETag = MD5? CORS works?
- **First song on the web:** about the end of week 2 (estimate).

**1b. Android (medium–large).**
- **Scope:** the Expo app on the SDK chosen in OPEN 5, an EAS development build (APK), login, library, album, mini player, background playback and the lock screen.
- **Tables:** + `devices`. **Routes:** `PUT /devices/:id`, plus the 1a library routes.
- **Done when:** 2 h of locked playback across an album on a real Android phone, with lock-screen next and previous.
- **First song on Android:** about week 3 (estimate).

**1c. iOS (medium).**
- **Scope:** the same app through EAS iOS and TestFlight internal testing, once the Apple decision (OPEN 1) is made. Until then iPhone friends use the web app in Safari: streaming and lock-screen controls, no offline.
- **Done when:** the same 2 h locked test on a real iPhone.

### 2. Must-haves by area

The orchestrator can split these into parallel tracks. Each area becomes a feature spec.

| area | screens | tables | routes | `features.csv` rows closed |
| --- | --- | --- | --- | --- |
| **A. Upload and library** (F01, F6) | S18 full (folder, multipart, resume, partial failure, storage full, unsupported, upload from mobile), S07 (filters, sort, search in library), S11, S05 | `upload_sessions`, `tracks`, `albums`, `artists`, `covers`, `jobs` | `uploads/*`, `tracks/:id` DELETE, `tracks/bulk-delete`, `tracks/:id/reprocess`, `library/*`, `artists/:id`, `home`; jobs `apply_sidecar_cover`, `regroup_batch`, `purge_track`, `library_cleanup` | Upload audio files; Read ID3 tags on upload; Your Library with filters; Sort and search inside Your Library; Album page built from tags; Artist page built from tags; Delete tracks and free storage; Bulk folder upload with resume; Keep stored copy bit for bit; Home with recently played and quick picks; also Duplicate detection on upload (should) |
| **B. Player** (F02, F04; fixes F2, F4) | S12 full, S13, S14 on web and mobile | `playback_state`, `play_events` | `playback-state` GET/PUT, `contexts/:type/:id/tracks`, `play-events`, `stream-urls` | Play pause skip previous seek; Persistent now playing bar across navigation; Full screen now playing view; Volume and mute; Shuffle; Repeat (off all one); Queue view with reorder and remove; Play next and add to queue; Lock screen and media session controls; Background playback on mobile; also Resume where you left off across devices (should) and Shuffle whole library and shuffle the queue (should) |
| **C. Playlists and favorites** (F03, F05) | S09, S16, S17, S08 | `playlists`, `playlist_items`, `favorites`, `tombstones` | `playlists*`, `favorites*` | Create rename delete playlist; Add and remove tracks in a playlist; Reorder tracks by drag; Liked Songs (heart a track), shipped as Favorites |
| **D. Search** (F06) | S06 | (indexes) | `search` | Search across own library (tracks albums artists playlists) |
| **E. Admin, account, settings** (F10 by admin link) | admin page, S21, S22 as "Account and space" (no plan), S03 "Forgot password?" → "Ask the person who invited you for a reset link" | `profiles`, `invites`, `devices` | `admin/*`, `me*`, `devices*` | Account settings (password and delete account; email change waits for SMTP → partial); Storage quota per plan with usage meter → shipped as the admin-set limit and space meter (partial: no plans); Password reset by email → admin link until a domain exists (partial) |
| **F. Export** (fix F7, export part) | S21 / account page | `playlists`, `play_events`, `tracks` | `export/*` | Export library on demand: playlists M3U8/CSV, history CSV and library CSV now; audio files later → partial |
| **G. Design rules** (fix F3) | all | — | — | Dark theme UI; Responsive web layout; No promotional pop-ups or custom rating prompts (policy) |
| **H. Offline downloads** (F07, fix F5), **L**, last | S24, download toggles on S08–S10 and S16, settings (cellular switch, space used) | `downloads`, `tombstones`, `devices` | `downloads/manifest`, `devices/:id/downloads` (PUT, remove), `sync`, `devices/:id` DELETE | Download for offline on mobile; also Offline indicator and downloaded filter (should) and Storage settings for downloads (should) |

### 3. Should-haves, then could-haves

- **Should:**
  - Edit track metadata and cover art: S19, `PATCH /tracks/:id`, `PATCH /albums/:id`, `POST /covers/uploads`.
  - Recently played plus a full history page: `GET /history`, using `play_events`.
  - Personal per-track play counts: already counted; this is UI work.
  - Smart playlists: `playlists.kind = 'smart'`, rules on genre, year, date added and play count.
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
  - Connect (realtime, later).
- **Optional milestones, triggered by the founder:**
  - The Subsonic `/rest` layer (~1 week).
  - `workers/transcode` (AAC 256 kbps for cellular streaming, ALAC, WAV).
  - Full audio export as a signed-URL manifest.
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
| F5 offline downloads | Area H: verified files in Documents, backup exclusion, tombstones at the next connection, remote device revoke, Wi-Fi by default. |
| F6 bulk upload, stored copy bit for bit | The audio pipeline and Area A: immutable object keys, MD5/ETag integrity, per-user duplicates, no cross-user deduplication, M3U import (should). |
| F7 export on demand | Area F for playlists, history and the library list. Full audio export is an optional milestone. The over-quota and retention rules are deferred. |
| F8 collector tools | `tracks.play_count` and history (should), smart playlists (should), search inside a playlist (`q` on the items route), an A–Z scrubber (client); more pins later. |

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

- **Where:** `apps/web/app/(marketing)/page.tsx`, served at `/` by the same Vercel project and domain as the app. `export const dynamic = 'force-static'`, server components only, no forms, analytics or third-party scripts. Atkinson Hyperlegible Next (400/600/700) is self-hosted through `next/font`.
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
| B2 egress and API calls | $0 (egress free up to 3× stored ≈ 1 TB; API calls free on pay-as-you-go per the snippets) | same |
| Supabase Free (Postgres + Auth), 2 projects | $0 (DB ~40–120 MB of 500 MB; 3 MAU of 50,000) | `supabase/supabase` `packages/shared-data/plans.ts` |
| Vercel Hobby | $0 (audio bypasses Vercel; extracting the whole import ≈ 0.7 Active-CPU-h of 4 included) | vercel.com/docs/plans/hobby (via search); function limit 300 s (Vercel changelog, via search 2026-10-04) |
| GitHub Actions | $0. Public repo: unlimited standard minutes. Private repo: 2,000 min/month, each job rounded up to a whole minute; budget ≈ 720 (hourly sweep) + 90 (nightly backup) + ~500 (CI) ≈ 1,300 min | search results 2026-10-04 (cicdcalculator.com, macrostack.net); GitHub's billing page not fetched |
| EAS Build Free | $0 (30 builds/month, up to 15 iOS) | docs.expo.dev/billing/plans (via search) |
| Resend Free (once a domain exists) | $0 (3,000/month, 100/day) | resend.com/pricing (via search) |
| **Total variable** | **≈ $2.3/month** | R2 instead: ≈ $5.0/month; Supabase Storage instead: ≈ $30/month |

**Sensitivity.** If each of the 3 users holds that library (~1 TB): B2 ≈ $7.1/month, R2 ≈ $15.3/month. Egress is still inside B2's allowance, and the database is still ~120 MB.

**Why the sweep is hourly, not every 30 minutes.** On a private repo, a 30-minute sweep alone uses 1,440 of the 2,000 free minutes (every run bills at least a minute), leaving too little for CI. Work normally runs inline through `after()`, so hourly only delays retries and expiries. With a public repo, 30 minutes is free.

**Fixed costs.**
- **Apple Developer Program:** US$99/year, required for TestFlight to friends' iPhones. Individuals get no fee waiver, and TestFlight builds expire after 90 days. Alternatives: web in Safari (no offline), or the Subsonic milestone with a free third-party client.
- **Domain:** about US$10–15/year, optional, not fetched.
- **Android:** $0 by sideloaded APK. Google Play Console is US$25 one-time, only if Play internal testing is ever wanted. Google's developer verification is planned to expand globally in 2027. Once it reaches Colombia, the free limited-distribution account (up to 20 devices) is the $0 path.
- **Year one:** about $99 + ~$12 (domain) fixed, plus ≈ $2.3/month variable.

**Time to first song** (estimates for one student at ~15 h/week):
- Milestone 0: days 1–3.
- Web: about the end of week 2.
- Android: about week 3.
- iPhone: 1–3 days after the Apple membership is active.
- Must-haves: weeks 4–8.
- Offline downloads: weeks 8–10.

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

1. **Apple Developer Program (US$99/year).** Options:
   - pay when the iOS build is ready (about week 3–4 at the earliest);
   - defer it, and iPhone friends use the web app in Safari;
   - build the Subsonic milestone, so they use a free client.
2. **Subsonic `/rest` milestone:** yes, no or later (≈ 1 week, a second route surface, weaker auth by design).
3. **Domain:** buy `tunehold.com` now (~US$10–15/year), or stay on `*.vercel.app`. A domain unlocks Resend SMTP, self-service invites and reset (F10), and the final bundle id (`com.tunehold.app` is a placeholder).
4. **Object storage:** B2 (default, ≈ $2.3/month, Content-MD5 unconfirmed, CORS through its CLI), or R2 (≈ $5.0/month, zero egress, simpler CORS). Both need a card past the free 10 GB.
5. **Expo SDK at the mobile slice:** wait for SDK 58 stable, start on the 58 prerelease, or start on 57 (single player, manual advance) and upgrade.
6. **Mac:** does the founder have one? It isn't needed for EAS cloud builds, but it is needed for the iOS Simulator, local iOS builds and debugging the backup-exclude module.
7. **Android distribution later:** the free limited-distribution account (≤ 20 devices) or Play Console ($25) once verification reaches Colombia (2027).
8. **Initial storage limit per friend, and the real size and format mix of the founder's library.** This sets the B2 cost (~$7/TB-month) and the import time.
9. **Supabase Free limits:** accept them (a week-idle pause countered by the hourly sweep; the nightly dump as the only backup), or move to Neon Free or Supabase Pro ($25/month) later.
10. **FLAC over cellular in v1** (~450 MB/hour, estimate), or build the optional AAC transcode worker earlier. Downloads default to Wi-Fi only either way.
11. **Repository visibility and name.** Public means unlimited Actions minutes and a 30-minute sweep. Private means the hourly sweep and the minutes budget above. `brand.md` asks to rename the repo before it is public or connected to a host, and Vercel builds project names and preview URLs from it.
12. **Account self-deletion:** immediate purge after typed confirmation (the proposed default), a grace period first, or admin-only for now.
13. **Favorites label:** "Favorites" or "Keepers" (`brand.md`). Code identifiers stay `favorites`.
14. **Landing copy:** keep card 2's "lighter copy for streaming" sentence (it describes the optional transcode worker) under "In progress", or drop it; soften card 1's resume line for non-Chromium browsers; and the `noindex` choice.
15. **Accepted formats and size cap:** MP3, AAC/M4A, FLAC and WAV up to 1 GiB per file (the proposal). ALAC: accept and flag as "plays on phones and Safari" (the proposal; whether Android plays ALAC is to verify on device), or reject until the transcode worker exists.

---

## Sources

Fetched or searched on 2026-10-04 in this phase and the judge pass. Search-snippet sources are marked "via search".

- Supabase plans and limits: `github.com/supabase/supabase` `packages/shared-data/plans.ts` and `pricing.ts`. SMTP limits: `apps/docs/content/guides/auth/auth-smtp.mdx`. Direct connection is IPv6-only; use the session pooler from GitHub Actions: `supabase.com/docs/guides/database/connecting-to-postgres` (via search).
- Backblaze B2 storage and transaction pricing: `backblaze.com/cloud-storage/pricing`, `/cloud-storage/transaction-pricing` (via search). B2 requires Content-MD5 on PutObject when Object Lock is on: `github.com/drakkan/sftpgo/issues/1336` (via search). B2 rejects the AWS SDK's new checksum headers; use `WHEN_REQUIRED`: `github.com/aws/aws-sdk-js-v3/issues/6810`, `github.com/jschneier/django-storages/issues/1498`, `github.com/nocobase/nocobase/issues/6872` (via search).
- Cloudflare R2 pricing: `developers.cloudflare.com/r2/pricing` (cloudflare-docs `r2/pricing.mdx`).
- Vercel Hobby: `vercel.com/docs/plans/hobby` (via search). Function duration 300 s on Hobby with Fluid compute: `vercel.com/changelog/higher-defaults-and-limits-for-vercel-functions-running-fluid-compute` (via search). vercel.com itself is blocked from this container.
- GitHub Actions free minutes (2,000/month for private repos, jobs rounded up to whole minutes): `cicdcalculator.com/github-actions-free-tier`, `macrostack.net/pricing/github-actions` (via search).
- Expo and expo-audio versions, typings and changelog: npm registry dist-tags and package tarballs (expo 58.0.3 `next` / 57.0.26 `latest`; expo-audio 58.0.5; expo-file-system 57.0.7). EAS plans: `docs.expo.dev/billing/plans` (via search).
- react-native-track-player: npm `latest` 4.1.2; v5 only as `5.0.0-alpha` nightlies (last 2025-09-24).
- Apple Developer Program and fee waivers: `developer.apple.com/programs`, `developer.apple.com/help/account/membership/fee-waivers` (via search).
- Android developer verification and the Play Console fee: `developer.android.com/developer-verification`, `support.google.com/googleplay/android-developer/answer/6112435` (via search).
- Resend pricing: `resend.com/pricing` (via search).
