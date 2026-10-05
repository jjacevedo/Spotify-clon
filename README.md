# Tunehold

Tunehold is a music player for the music you own, on the web, iPhone and Android. You upload your own files, and it is being built to store each one as you uploaded it and play it in your order. It is in development, for its maker and a few friends, and accounts are by invite.

This repository holds the web app (with the landing page and the API) and the shared packages. The mobile app arrives in a later milestone.

## Requirements

- Node.js 22 (see `.nvmrc`).
- pnpm 10.34.6, the version in `package.json` (`packageManager`). Either run `corepack enable` once, so the right version is used automatically, or install it with `npm i -g pnpm@10.34.6`.
- Python 3 for the brand gate (standard library only).

Works on macOS and Linux.

## Commands

Run them from the repository root.

```bash
pnpm install       # install every workspace
pnpm dev           # web app on http://localhost:3000
pnpm lint          # Prettier check, then ESLint in every workspace
pnpm typecheck     # TypeScript (strict) in every workspace
pnpm test          # unit tests (Vitest)
pnpm build         # production build of the web app
pnpm format        # format every file with Prettier
pnpm brand-gate    # brand sweep and contrast checks (scripts/brand-gate.sh)
```

End-to-end tests (Playwright, Chromium) build the web app and start it on port 3100:

```bash
# once per machine: download the Chromium build that Playwright expects
pnpm --filter @tunehold/web exec playwright install chromium

pnpm --filter @tunehold/web e2e
```

In the development container, Chromium is already installed. Point Playwright at it instead of downloading anything:

```bash
PLAYWRIGHT_BROWSERS_PATH=/opt/pw-browsers pnpm --filter @tunehold/web e2e
```

The build downloads the Atkinson Hyperlegible Next font once and serves it from the app. Behind an HTTPS proxy, run the build with `NODE_USE_ENV_PROXY=1` so Node uses the proxy settings.

Design tokens come from `replica/design/tokens.json`. After changing that file, regenerate the TypeScript and CSS exports and commit them:

```bash
pnpm --filter @tunehold/tokens generate
```

## Repository layout

```
apps/web/             Next.js app: the landing page at /, the API under /api/v1
  app/                routes (App Router)
  src/marketing/      landing page copy, feature status and components
  e2e/                Playwright tests
packages/config/      shared TypeScript and ESLint presets
packages/tokens/      design tokens as TypeScript and as a Tailwind theme
scripts/              repository scripts (brand gate)
replica/              product research, architecture, design and brand documents
.claude/workflow/     specs and the development workflow
```

## More

- Architecture, stack and build order: `replica/architecture.md`.
- Specs and the development workflow: `.claude/workflow/`.
