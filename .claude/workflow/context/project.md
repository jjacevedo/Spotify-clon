# Project: Tunehold

Formerly code-named tunebox; earlier research docs in replica/ use that codename.

## What it is

A music player for web + iOS + Android, **for personal use for now** (the founder and a few friends; invite-only accounts). Payments, pricing, legal work, store listings and market validation are deferred (see `replica/deferred.md`); a public launch may come much later. Users **upload their own audio files** to the cloud, organize them in a library and playlists, and play them on every device with a queue, offline downloads and playlist sharing. It's a clean-room rebuild of Spotify's features and flows (see `replica/recon.md`), never of its code, brand, copy or catalogue. Product name **Tunehold**, chosen in the `/replica-brand` phase (see `replica/brand.md`; screening checks only, a trademark lawyer still has to search before money is spent on the name).

## Status (2026-10-04)

- Phase 1 (`/replica-recon`) is done: `replica/recon.md` (27 screens S01–S27, 12 flows F01–F12, components, data model) and `replica/features.csv` (feature matrix).
- No app code yet. The **stack is not decided**. `/replica-architect` decides it (phase 3) and writes `replica/architecture.md`.
- When the architect phase closes, update this file's "Stack" and "Commands" sections with the real values.

## Stack

Decided in `/replica-architect` (2026-10-04). Full table, schema, API and build order are in `replica/architecture.md`, and the SQL is in `replica/schema.sql`.

- **Monorepo:** pnpm workspaces + Turborepo, TypeScript `strict`, Node 22 LTS. Apps: `apps/web`, `apps/mobile`. Packages (`@tunehold/*`): `contract`, `db`, `player-core`, `media`, `storage`, `tokens`, `config`.
- **Web + API + landing:** Next.js (current stable, App Router) as one Vercel Hobby project (`iad1`). The landing page is at `/` (`app/(marketing)`), the app under `app/(app)`, REST under `/api/v1`, and the sweep at `/api/cron/sweep`. Tailwind CSS v4 themed from `replica/design/tokens.json`, Radix UI, TanStack Query and Virtual, dnd-kit, Zustand.
- **Mobile:** Expo SDK 58 (required; SDK 57 is not a fallback) + expo-router, EAS development builds (no Expo Go). expo-audio (`AudioPlaylist` with an append-only window, recovery through a `pnpm patch` or a playlist rebuild, lock screen, background, `doNotMixPersistent`), expo-file-system (foreground-first transfer queue for uploads and downloads), expo-sqlite in a backup-excluded folder (offline mirror, index with scope links, outbox, session), FlashList, expo-image. Bundle id / package `app.tunehold.mobile` (frozen).
- **Database:** Supabase Postgres Free (dev and prod projects) with `pg_trgm` and `unaccent`. Drizzle ORM; plain-SQL migrations in `packages/db/migrations` applied by `drizzle-kit migrate` (never `push`); postgres.js through the Supavisor transaction pooler. Two roles: `tunehold_app` (API requests, RLS applies) and the owner (jobs, sweep, admin, migrations). Storage counters are kept by triggers.
- **Access rules:** row level security with real policies for `tunehold_app` (each request is one transaction that starts with `set_config('app.uid', …, true)`), plus owner-scoped repositories, the Data API off, composite owner foreign keys, and a second-user suite generated from the route table.
- **Auth:** Supabase Auth, email + password, invite-only (sign-ups off; admin `generateLink`; settings checked in as `supabase/config.toml`). Cookies on web (`@supabase/ssr`), Bearer + `getClaims` on mobile (Bearer wins when both are present). Requests from a revoked device's session get `401 device_revoked`. No email provider in v1.
- **Files:** Backblaze B2 private bucket through the S3 API (`@aws-sdk/client-s3`, checksum mode `WHEN_REQUIRED`), presigned PUT/GET only, with Content-Length, Content-Type and Content-MD5 fixed in every upload signature. Stream URLs last 2 h. Audio never passes through Vercel. Cloudflare R2 is the env-var swap.
- **Media:** `music-metadata` + `@tokenizer/s3`, `file-type` (over the range tokenizer), `sharp` (with pixel limits). Web uploads use Uppy (`@uppy/aws-s3`, headless) + `hash-wasm`.
- **Jobs:** a Postgres `jobs` table run by `after()`. GitHub Actions runs the sweep hourly and a nightly `age`-encrypted `pg_dump` to a B2 backups bucket. A Vercel daily cron is the second trigger. A Postgres fixed-window rate limiter guards the expensive routes.
- **Payments:** deferred (`replica/deferred.md`).
- **Tests:** Vitest (packages, repositories, second-user suite), Playwright for web e2e (Chromium preinstalled at `/opt/pw-browsers`), GitHub Actions CI, an on-device checklist for mobile playback.

## Current structure

```
CLAUDE.md                  project rules (authorship, workflow, Codex)
.claude/settings.json      enables the codex@openai-codex plugin
.claude/skills/replica-*/  the 11 Replica skills (phase method)
.claude/agents/            subagents: architect, frontend-developer, backend-developer, qa-reviewer, tech-lead
.claude/workflow/          this workflow: WORKFLOW.md, context/, specs/, state.json
replica/recon.md           recon map (screen/flow IDs referenced by every spec)
replica/features.csv       feature matrix; the `clone` column is filled during the build
replica/screens/           reference screenshots (never shipped)
```

Every later Replica phase writes to `replica/` (`entrepreneur.md`, `architecture.md`, `design/tokens.json`, `test-plan.md`, ...).

## Commands

Available today (standard-library Python 3, no dependencies):

```bash
python3 .claude/skills/replica-diff/parity.py replica/features.csv          # parity score + missing list
python3 .claude/skills/replica-design/contrast.py replica/design/tokens.json # WCAG contrast of the tokens
python3 .claude/skills/replica-brand/sweep.py . --config replica/brand.json # leftovers of the original (report: exits 1 on the 9 instruction lines in replica/brand.md#sweep; the gate is constraint 2)
python3 .claude/skills/replica-diff/imgdiff.py original.png clone.png --out diff.png
python3 .claude/skills/replica-launch/listing.py replica/launch/listing.json
python3 .claude/skills/replica-entrepreneur/reviews.py replica/reviews.csv
```

App commands: **planned, created by the first build task** (milestone 0, the scaffold + landing task in `replica/architecture.md`). The commands marked (M1a) arrive with the web slice and the ones marked (M1b) with the Android slice. Until a command exists in `package.json`, no developer can claim it passes.

```bash
# planned — created by the first build task (milestone 0)
pnpm install                                   # whole monorepo (pnpm workspaces)
pnpm dev                                       # turbo: apps/web on http://localhost:3000
pnpm lint                                      # eslint, every workspace
pnpm typecheck                                 # tsc --noEmit, every workspace (strict)
pnpm test                                      # vitest, every workspace that has tests
pnpm build                                     # turbo build (web: next build; packages: tsc)
pnpm --filter @tunehold/web build              # web only
python3 .claude/skills/replica-brand/sweep.py apps/web --config replica/brand.json   # deploy gate, must exit 0

# planned — created by the web slice (M1a)
pnpm --filter @tunehold/db db:migrate          # drizzle-kit migrate against DATABASE_URL_DIRECT
pnpm --filter @tunehold/db db:seed             # admin profile for ADMIN_EMAIL
pnpm test:db                                   # repository + second-user suite; needs DATABASE_URL_TEST (Postgres 17)
PLAYWRIGHT_BROWSERS_PATH=/opt/pw-browsers pnpm --filter @tunehold/web e2e   # Playwright web e2e
psql "$DATABASE_URL_TEST" -v ON_ERROR_STOP=1 --single-transaction -f replica/schema.sql   # schema smoke run: the previous revision passed on PG16.14 in review; the current one is not executed yet (run it, plus "Schema checks before 1a" in replica/architecture.md, before milestone 1a)
python3 .claude/skills/replica-brand/sweep.py packages --config replica/brand.json      # must exit 0

# planned — created by the Android slice (M1b)
pnpm --filter @tunehold/mobile start           # expo start --dev-client
pnpm --filter @tunehold/mobile typecheck
pnpm --filter @tunehold/mobile test            # vitest on pure modules (offline/sync logic); no RN test runner in v1
pnpm --filter @tunehold/mobile exec eas build --profile development --platform android
pnpm --filter @tunehold/mobile exec eas build --profile preview --platform android    # internal APK for friends
pnpm --filter @tunehold/mobile exec eas build --profile testflight --platform ios     # after the Apple Developer Program decision
python3 .claude/skills/replica-brand/sweep.py apps/mobile --config replica/brand.json  # must exit 0
```

Codex (second reviewer, run by the orchestrator in the main session):

```bash
node /opt/codex-plugin-cc/plugins/codex/scripts/codex-companion.mjs setup --json   # readiness check
codex login --device-auth                                                         # once per session
```

## Git

- **Base branch:** `cl/great-gauss-36g7dv`. It's the only branch on the remote and there is no `main`.
- Feature branches: `feature/<feature-key>`, created from the base branch (the `developer` worktree).
- Author of every commit: `Juan José Acevedo Otálvaro <178350246+jjacevedo@users.noreply.github.com>`. No AI attribution lines.
- Commit convention (from the history): short subject in English, imperative ("Add …", "Fix …"), or `<Phase>: <summary>` for Replica phases (e.g. `Recon: map …`). Optional body explaining the why.
