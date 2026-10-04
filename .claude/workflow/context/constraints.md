# Constraints

## Scope and legal

1. **Clean-room.** Rebuild functionality and UX patterns, never Spotify's code, logo, name, green, Circular font, copy, illustrations or private APIs. Write every line fresh.
2. **The word "Spotify" never appears** in code, identifiers, assets, user-facing copy or commits for app code. Use `tunebox`. `sweep.py --avoid "Spotify"` must come out clean before deploy. The only exceptions are reference documents under `replica/` and `.claude/workflow/` (recon, specs) that describe the original.
3. **No catalogue.** tunebox only plays files the user uploaded. No integration with licensed catalogues or lyrics.
4. **Copyright on uploads.** Any feature that makes content visible to other people (sharing, public profiles, collaborative playlists) needs reporting/takedown (F11, S26), rate limits, and recipients can't download. Raise it in the spec if it's missing.
5. **Out of scope** (`skip` rows in `features.csv`): recommendations from a global catalogue, AI DJ, Wrapped, Jam/Blend, ads, partner integrations. Don't implement them without explicit approval.

## Process

1. **Replica phases rule.** The order is in `CLAUDE.md`. This multi-agent workflow applies inside the phases that produce code (mainly build, backend and fixes from test/diff), not in phases that only write documents.
2. **Approvals belong to the user.** Never push, merge into the base branch, or delete branches or worktrees without the user's explicit approval. Never `--force`, never `reset --hard` on shared branches, never rewrite history.
3. **Authorship.** Commits as `Juan José Acevedo Otálvaro <178350246+jjacevedo@users.noreply.github.com>`. No `Co-Authored-By`, `Claude-Session` or any mention of AI in commits, PRs, code or docs.
4. **No dependencies without approval.** A new library or service goes in the spec, or is reported as BLOCKED.
5. **Evidence over claims.** Nobody declares success without having run the verification commands from `project.md` and pasted the result (summarized).
6. **Spec first** for medium and large changes. Nothing gets implemented outside the spec. Anything ambiguous is reported as BLOCKED or as an open decision, never guessed.
7. **Max 2 QA cycles** per feature. After that the user decides.
8. **Codex** (if available) is a second reviewer on medium and large changes. The orchestrator verifies its findings before applying them.
9. **Language.** Specs and code in English. Communication with the user in Spanish.

## Technical (apply once the stack exists; the architect confirms them)

1. TypeScript strict on web, mobile and backend. No `any` without justification.
2. Business rules and validation on the server. Validate inputs at the edges (API, uploads).
3. Audio is never served directly from public storage. Use short-lived signed URLs, checked against the owner or the share link.
4. Uploads: validate the real MIME type and size, quota per plan, and handle partial failure.
5. Player: playback must not cut out when the route changes (shared global player).
6. Every list has empty, loading and error states, as `recon.md` records them.
7. Accessibility: AA contrast (`contrast.py`), keyboard navigation on web, labels on icon-only buttons.
8. Tests: unit tests for logic, and Playwright for the flows touched (F01–F12) once e2e is set up.
9. Secrets never go in the repo. Use environment variables documented in the spec.
