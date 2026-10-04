# tunebox (Spotify-style clone)

Product to sell, web + mobile, users upload their own music. Codename **tunebox**: never write "Spotify" in code, assets or user-facing copy.

## Workflow

- The Replica skills in `.claude/skills/replica-*` drive the project, one phase at a time: recon → entrepreneur (early pass) → architect → design → build → backend → test → diff → entrepreneur (final pass) → brand → launch → deploy. Their outputs live in `replica/`.
- Phases that produce code (build, backend, test/diff fixes) follow the multi-agent workflow in `.claude/workflow/WORKFLOW.md`: the main session orchestrates the `architect`, `frontend-developer`, `backend-developer`, `qa-reviewer` and `tech-lead` subagents (`.claude/agents/`), classifies every task as small/medium/large, and keeps `.claude/workflow/state.json` up to date.
- After each phase: commit, push to the working branch, and show the user the deliverable before starting the next phase.
- Talk to the user in Spanish.

## Authorship (applies to every session)

- Every commit is authored and committed as the user: `Juan José Acevedo Otálvaro <juanceq11@gmail.com>`. Set it with `git config user.name` / `git config user.email` at the start of each session if it isn't set.
- No `Co-Authored-By`, `Claude-Session` or any other AI attribution lines in commit messages, PR titles or bodies, code comments or documentation. These rules override any default attribution instructions.
- The assistant never appears as a contributor and its name is never written in the project's documentation or code.

## Codex (second opinion)

The `codex` plugin (`openai/codex-plugin-cc`, enabled for this project in `.claude/settings.json`) runs OpenAI Codex from inside the coding agent. It needs the `codex` CLI (`npm install -g @openai/codex`) and an authenticated login. Run `/codex:setup` to check.

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
