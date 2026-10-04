# Spec: <feature-key> — <short title>

- Size: medium | large
- Replica phase: build | backend | test-fix | diff-fix
- Status: draft | approved
- References: screens S__, flows F__, rows in `replica/features.csv`: "<feature>", ...

## Problem

What is missing or broken, and for whom. One paragraph.

## Scope

**In:**
- ...

**Out:**
- ... (and why)

## Files

| path | action (create/modify) | what changes |
| --- | --- | --- |
| | | |

## Contracts

Types, API endpoints (method, route, request, response, errors), DB tables/columns, events, environment variables. Exact enough for frontend and backend to work in parallel.

```ts
// example
```

## Tracks (large only)

| track | agent | files it owns | depends on |
| --- | --- | --- | --- |
| A | backend-developer | | — |
| B | frontend-developer | | contract X of track A |

Tracks must not touch the same files.

## Acceptance criteria

- [ ] AC1: observable, testable behaviour (include the empty, loading and error states)
- [ ] AC2: ...
- [ ] Verification: commands that must pass (from `context/project.md`)
- [ ] `features.csv`: rows to set to `yes` or `partial`

## Risks and open decisions

- Risk: ... → mitigation
- OPEN: ... (the user decides before implementation starts)
