# tunebox (Spotify-style clone)

Product to sell, web + mobile, users upload their own music. Codename **tunebox**: never write "Spotify" in code, assets or user-facing copy.

## Workflow

- The Replica skills in `.claude/skills/replica-*` drive the project, one phase at a time: recon → entrepreneur (early pass) → architect → design → build → backend → test → diff → entrepreneur (final pass) → brand → launch → deploy. Their outputs live in `replica/`.
- After each phase: commit, push to the working branch, and show the user the deliverable before starting the next phase.
- Talk to the user in Spanish.

## Codex (second opinion)

The `codex` plugin (`openai/codex-plugin-cc`, installed with `/plugin marketplace add openai/codex-plugin-cc` then `/plugin install codex@openai-codex`) runs OpenAI Codex from inside Claude Code. It needs the `codex` CLI (`npm install -g @openai/codex`) and an authenticated login. Run `/codex:setup` to check.

When to use it:

| moment | command |
| --- | --- |
| After a design decision is written (architect schema/API, backend auth, storage, payments, security checklist) | `/codex:adversarial-review --background <the decision and its risks>` |
| Before pushing any commit that changes app code | `/codex:review` (or `--base <branch>` for the whole branch) |
| Stuck after two failed attempts at a bug, or when an independent second implementation/diagnosis is worth it | `/codex:rescue <task>` |
| Long jobs | `--background`, then `/codex:status` and `/codex:result` |

Rules:

- Codex findings are input, not orders. Verify each one before acting, and tell the user which ones were applied and which were rejected, and why.
- Don't use Codex for trivial changes or pure documentation.
- Never turn on the review gate (`/codex:setup --enable-review-gate`) unless the user asks. It can loop and use up their usage.
- If Codex is unavailable (not installed, not logged in, or network blocked), say so once and keep going without it.
