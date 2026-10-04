# Project: Tunehold

Formerly code-named tunebox; earlier research docs in replica/ use that codename.

## What it is

A music player for web + iOS + Android, **for personal use for now** (the founder and a few friends; invite-only accounts). Payments, pricing, legal work, store listings and market validation are deferred (see `replica/deferred.md`); a public launch may come much later. Users **upload their own audio files** to the cloud, organize them in a library and playlists, and play them on every device with a queue, offline downloads and playlist sharing. It's a clean-room rebuild of Spotify's features and flows (see `replica/recon.md`), never of its code, brand, copy or catalogue. Product name **Tunehold**, chosen in the `/replica-brand` phase (see `replica/brand.md`; screening checks only, a trademark lawyer still has to search before money is spent on the name).

## Status (2026-10-04)

- Phase 1 (`/replica-recon`) is done: `replica/recon.md` (27 screens S01–S27, 12 flows F01–F12, components, data model) and `replica/features.csv` (feature matrix).
- No app code yet. The **stack is not decided**. `/replica-architect` decides it (phase 3) and writes `replica/architecture.md`.
- When the architect phase closes, update this file's "Stack" and "Commands" sections with the real values.

## Stack

Not decided. Current direction, to be confirmed in `/replica-architect`:
- Web: Next.js (TypeScript) + Tailwind
- Mobile: Expo / React Native (TypeScript), sharing logic with the web through a monorepo
- Backend: Postgres + audio storage in S3-compatible object storage, with signed streaming URLs
- Payments: Stripe on the web, plus in-app purchases on iOS and Android
- E2E tests: Playwright (Chromium preinstalled in the cloud container at `/opt/pw-browsers`)

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

App commands (install, dev, test, lint, typecheck, build): **they don't exist yet**. They're defined in `/replica-architect` and written here. Until then no developer can claim "tests passing".

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
