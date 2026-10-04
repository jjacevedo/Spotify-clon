# Multi-agent workflow

The **orchestrator is the main session**. It launches the subagents with the Agent tool. Subagents never launch each other. All of them report back to the orchestrator, and the orchestrator summarizes each result to the user in a few lines.

## How it fits the Replica method

- The Replica phases (`CLAUDE.md`) set *what* gets built and in what order. This workflow sets *how* each change that touches code gets built.
- Document-only phases (recon, entrepreneur, design, brand, launch) are run by the orchestrator with the skill. Exception: `/replica-architect` can be delegated to the `architect` agent, which writes `replica/architecture.md`.
- Code phases (build, backend, test fixes, diff fixes): each screen, flow or block from `features.csv` becomes a feature with its key (e.g. `upload-pipeline`, `player-shell`) and goes through the flow below.
- Specs live in `.claude/workflow/specs/<feature-key>.md` and reference the IDs from `replica/recon.md` (S__, F__) and the rows of `replica/features.csv`.

## Agents

| agent | does | never |
| --- | --- | --- |
| `architect` | spec before code; validation against the spec at the end | writes app code |
| `frontend-developer` | web + mobile UI per the spec, with tests, commit on its branch | push, merge |
| `backend-developer` | API, DB, audio pipeline, auth, payments per the spec, with tests, commit on its branch | push, merge |
| `qa-reviewer` | read-only review → APPROVED / REQUEST_CHANGES | edits files |
| `tech-lead` | local merge of approved work into the base branch and verification | push, `--force`, deleting branches |

## Classify first

Before each task, the orchestrator tells the user in one line which size it assigned.

### Small
Typo, 1–2 files, no relevant behaviour change. The orchestrator does it directly and verifies it. No spec, no agents.

### Medium
1. The orchestrator writes a short spec (from `_TEMPLATE.md`), or asks `architect` for it if contracts are involved.
2. `frontend-developer` or `backend-developer` implements it on `feature/<key>` with `isolation: "worktree"`.
3. `qa-reviewer` reviews. **In parallel, Codex `review`** as a second reviewer, if available.
4. REQUEST_CHANGES → back to the developer with the findings. **Max 2 cycles**, then the user decides.
5. APPROVED → the user approves the integration → `tech-lead` merges locally.

### Large
1. `architect` writes the spec and splits it into independent tracks when possible. **Codex `adversarial-review` of the design**, if available.
2. **The user approves the spec.**
3. One developer per track, in parallel, each with `isolation: "worktree"`.
4. `qa-reviewer` reviews each track (plus Codex `review`).
5. **The user approves the integration.**
6. `tech-lead` does the local merge into the base branch and verifies it.
7. `architect` validates against the spec.
8. **The user approves the push and the branch/worktree cleanup.**

## Rules

- Update `.claude/workflow/state.json` at every stage change.
- Stages: `planning → development → qa_review → integration → validation → complete`.
- Never push, merge into the base branch, or delete branches or worktrees without the user's explicit approval.
- If an agent reports **BLOCKED** or an open decision, the orchestrator asks the user instead of deciding.
- Codex findings are verified before being applied, and the user is told which ones were applied and which were rejected.
- Summarize each agent's result in a few lines. Don't paste its full output.

## state.json

```json
{
  "base_branch": "cl/great-gauss-36g7dv",
  "features": {
    "<feature-key>": {
      "status": "in_progress | blocked | changes_requested | approved | merged | validated | complete",
      "current_stage": "planning | development | qa_review | integration | validation | complete",
      "spec": ".claude/workflow/specs/<feature-key>.md",
      "branch": "feature/<feature-key>",
      "commits": ["<sha>"],
      "qa_result": { "decision": "APPROVED | REQUEST_CHANGES", "cycle": 1, "findings": [] },
      "history": [
        { "stage": "planning", "agent": "architect", "at": "2026-10-04T12:00:00Z", "note": "spec draft" }
      ]
    }
  }
}
```

## Codex in this workflow

Run by the orchestrator in the main session (subagents don't call it):

```bash
node /opt/codex-plugin-cc/plugins/codex/scripts/codex-companion.mjs review --base cl/great-gauss-36g7dv
node /opt/codex-plugin-cc/plugins/codex/scripts/codex-companion.mjs adversarial-review "<focus>"
```

If `/opt/codex-plugin-cc` doesn't exist, clone `openai/codex-plugin-cc` into the scratchpad. If the session isn't logged in, run `codex login --device-auth` and give the user the link and code. If Codex is unavailable, say so once and carry on without it.
