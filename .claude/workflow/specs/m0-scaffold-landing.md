# Spec: m0-scaffold-landing — Monorepo scaffold, CI and the landing page

- Size: medium
- Replica phase: build (milestone 0, "First code task: scaffold + landing page" in `replica/architecture.md`)
- Status: draft (2026-10-05)
- References: screen S01 (landing, states "default" and "mobile"); no flow; `replica/features.csv` has no row for the landing page (see Acceptance criteria)
- Sources: `replica/architecture.md` (Stack, Dependencies, Environment variables, Repo layout, Build order 0, Landing page, Open decisions, founder decisions of 2026-10-05), `replica/launch/landing.md` (copy and Build notes), `replica/design/tokens.json`, `replica/brand.md`, `replica/brand.json`, `.claude/workflow/context/project.md`, `.claude/workflow/context/constraints.md`
- Branch: `feature/m0-scaffold-landing` (one track, `frontend-developer`, worktree)

## Problem

The repository has no code yet. Before any backend exists, Tunehold needs the monorepo every later milestone builds on (pnpm workspaces, Turborepo, strict TypeScript, shared lint and TypeScript presets, design tokens wired into Tailwind v4), a CI that runs lint, typecheck, tests, build and the brand gates, and the one public page: the landing page at `/`, with its copy taken verbatim from `replica/launch/landing.md`. It is for the founder and the friends he shows it to, and it proves the Vercel and CI path. The commands that `project.md` lists as "planned (milestone 0)" stop being plans when this lands.

## Scope

**In:**
- **Root workspace.** `package.json` (scripts `dev`, `lint`, `typecheck`, `test`, `build`, `format`, `brand-gate`), `pnpm-workspace.yaml` (workspaces, a version catalog, `allowBuilds`), `pnpm-lock.yaml`, `turbo.json`, `.nvmrc` (`22`), `.gitignore`, `.editorconfig`, `.prettierrc.json`, `.prettierignore`, `scripts/brand-gate.sh`, `README.md`.
- **`packages/config` (`@tunehold/config`).** TypeScript presets (strict) and ESLint flat-config presets (base, Next.js). No build step, no tests.
- **`packages/tokens` (`@tunehold/tokens`).** A generator (`scripts/generate.mjs`, plain Node, no dependency) that reads `replica/design/tokens.json` and writes a typed TS export and a Tailwind v4 theme CSS file (both committed), plus a Vitest suite that fails when either generated file has drifted from the JSON. Source-only package (no build output).
- **`apps/web` (`@tunehold/web`).** Next.js 16 App Router with:
  - the landing page at `/` (`app/(marketing)/page.tsx`, `force-static`), copy verbatim from `landing.md`, structure, themes, type, accessibility and behaviour from its Build notes;
  - page metadata: title, description, `robots: noindex`, Open Graph title and description (no OG image, see Out);
  - `GET /api/v1/health` with a Vitest test;
  - a plain "T" favicon (`app/icon.svg`), as the Build notes allow until the logo exists;
  - `vercel.json` with `regions: ["iad1"]`;
  - Playwright e2e for the landing page and the health route, run against the preinstalled Chromium.
- **`.github/workflows/ci.yml`.** Install, lint, typecheck, test, build, and the brand gate (sweep of `apps/web` and `packages`, the labels sweep, the Title-case grep, contrast of both colour blocks).
- **`replica/build-log.md`.** Created, with the S01 line (the `/replica-build` skill keeps this log).

**Out:**
- Supabase, B2, auth, `packages/contract|db|storage|media|player-core`, any app screen, `/login`: milestone 1a. So the header shows no "Log in" link and the final section uses its no-sign-in variant (Build notes, "Call to action").
- `apps/mobile`: milestone 1b.
- `sweep.yml` and `backup.yml`: milestone 1a. Because the repository is public (founder decision, 2026-10-05), `sweep.yml` can run every 30 minutes instead of hourly when it lands.
- E2E and database tests in CI: database tests arrive with 1a, and e2e in CI waits for the founder's answer (OPEN 3). In M0, e2e runs locally and in QA.
- Security headers and CSP: they arrive with the request proxy in 1a. Next.js 16 renamed `middleware.ts` to `proxy.ts`, so 1a should use the new name. The landing page has no forms, user data or third-party scripts.
- Open Graph image: the lockup in the logo brief doesn't exist yet (OPEN 4).
- Optional `prefers-color-scheme: dark` switch for the light sections (an optional item in `landing.md`).
- `.env.example`, `.npmrc`, root `tsconfig.base.json`: M0 reads no variables. pnpm 11+ reads only auth and registry settings from `.npmrc`. The TypeScript presets live in `packages/config`.
- Vercel project creation and the first deploy: these are founder actions, listed under "Founder follow-up" below.
- A skip link, a custom 404 page, analytics, cookies, any third-party script: they aren't in `landing.md`, which forbids analytics and tracking.
- Screenshots in `replica/clone-screens/`: there is no reference screenshot for S01, and the landing page is Tunehold's own page, not a rebuild of the original's.

**Deviations from `replica/architecture.md`, with reasons:**
1. The landing page has one small client component, the "See how it works" link, because `landing.md` asks that focus moves to the "How it works" heading after the jump. A plain in-page link only moves the focus starting point, so it can't do that reliably. The page stays `force-static` with no data and no third-party code. Everything else is a server component.
2. Workspace packages are source-only (TS consumed through `transpilePackages`), so `pnpm build` builds only `apps/web`. `project.md` said "packages: tsc", but there is nothing to emit yet.
3. Prettier config sits at the root, not in `packages/config`, because one formatter covers the whole workspace.
4. The health route returns `{ ok: true, version }` as `architecture.md` (Infrastructure) specifies, not the `{ status: 'ok' }` of the task brief (OPEN 2).
5. The e2e command (`project.md` lists it under M1a) is created now, because the landing page needs it.

## Files

Every file below is new (the repository has no code yet). Don't use `create-next-app`, `create-turbo` or any template. They ship third-party logos (`favicon.ico`, `next.svg`, `vercel.svg`), the Geist font and their own copy, and none of that may ship.

| path | action | what it contains |
| --- | --- | --- |
| `package.json` | create | `name: "tunehold"`, `private: true`, `type: "module"`, `packageManager: "pnpm@12.9.1"`, `engines.node: "22.x"`. Scripts: `dev: turbo run dev`; `lint: prettier --check . && turbo run lint`; `typecheck: turbo run typecheck`; `test: turbo run test`; `build: turbo run build`; `format: prettier --write .`; `brand-gate: bash scripts/brand-gate.sh`. devDependencies: `turbo`, `prettier`, `typescript` (catalog) |
| `pnpm-workspace.yaml` | create | `packages: [apps/*, packages/*]`; `catalog:` with the versions shared by more than one workspace (see Dependencies); `allowBuilds:` listing exactly the packages that the first `pnpm install` reports as having build scripts, each `false` unless the package fails without its script (expected: `sharp`, `@tailwindcss/oxide`, `unrs-resolver`, possibly `esbuild`). No other keys, because pnpm 12 rejects unknown settings |
| `pnpm-lock.yaml` | create | generated by `pnpm install`, committed |
| `turbo.json` | create | `tasks`: `build` (`dependsOn: ["^build"]`, `outputs: [".next/**", "!.next/cache/**"]`), `lint`, `typecheck`, `test` (`outputs: []`), `dev` (`cache: false`, `persistent: true`). `globalDependencies: ["replica/design/tokens.json", "replica/launch/landing.md", "replica/brand.json"]`, because tests read them. `globalPassThroughEnv: ["HTTPS_PROXY", "HTTP_PROXY", "NO_PROXY", "NODE_EXTRA_CA_CERTS", "SSL_CERT_FILE", "NODE_USE_ENV_PROXY"]`, so that `next build` can fetch the font through a proxy under turbo's strict env mode |
| `.nvmrc` | create | `22` |
| `.gitignore` | create | `node_modules/`, `.next/`, `.turbo/`, `dist/`, `coverage/`, `*.tsbuildinfo`, `next-env.d.ts`, `.vercel/`, `.env*` (with `!.env.example`), `test-results/`, `playwright-report/`, `blob-report/`, `.DS_Store` |
| `.editorconfig` | create | UTF-8, LF, 2-space indent, final newline, trim trailing whitespace (not for `*.md`) |
| `.prettierrc.json` | create | `{ "singleQuote": true, "trailingComma": "all", "printWidth": 100 }` |
| `.prettierignore` | create | `replica/`, `.claude/`, `CLAUDE.md`, `pnpm-lock.yaml`, `packages/tokens/src/generated/`, `**/.next/`, `**/.turbo/` |
| `scripts/brand-gate.sh` | create | `#!/usr/bin/env bash`, `set -euo pipefail`, run from the repo root. Runs, in order: sweep `apps/web` and `packages` with `--config replica/brand.json`; sweep both with `--avoid "Liked Songs,Smart Shuffle,Discover Weekly,Daily Mix"`; `! grep -rnI --exclude-dir=node_modules --exclude-dir=.next "Your Library" apps packages`; `contrast.py replica/design/tokens.json`; contrast of the light block through a `mktemp` copy with `color` replaced by `color-light` (command in Verification). Exits non-zero on the first failure |
| `README.md` | create | What Tunehold is (two or three sentences in the brand voice: plain, calm, exact; it's in development for its maker and a few friends). Requirements (Node 22, pnpm 12.9.1 through `npm i -g pnpm@12.9.1` or corepack). Commands (install, dev, lint, typecheck, test, build, e2e with the `PLAYWRIGHT_BROWSERS_PATH` note, plus `playwright install chromium` on a normal machine, brand-gate). Repo layout. Pointers to `replica/architecture.md` and `.claude/workflow/`. Works on macOS and Linux. No mention of the original's name or of any tool that wrote code |
| `.github/workflows/ci.yml` | create | See Contracts, "CI" |
| `packages/config/package.json` | create | `name: "@tunehold/config"`, `private`, `type: "module"`, `exports`: `./tsconfig/base.json`, `./tsconfig/nextjs.json`, `./tsconfig/library.json`, `./eslint/base` → `./eslint/base.js`, `./eslint/next` → `./eslint/next.js`. dependencies: `@eslint/js`, `typescript-eslint`, `eslint-config-next`. peerDependencies: `eslint`, `typescript` |
| `packages/config/tsconfig/base.json` | create | Set explicitly (TypeScript 6 changed several defaults): `strict: true`, `noUncheckedIndexedAccess: true`, `noImplicitOverride: true`, `noFallthroughCasesInSwitch: true`, `forceConsistentCasingInFileNames: true`, `isolatedModules: true`, `esModuleInterop: true`, `resolveJsonModule: true`, `skipLibCheck: true`, `noEmit: true`, `target: "ES2022"`, `module: "ESNext"`, `moduleResolution: "Bundler"`, `lib: ["ES2023"]`, `types: []` (each workspace lists its own). No `baseUrl` (deprecated in TS 6) |
| `packages/config/tsconfig/nextjs.json` | create | extends base; `lib: ["ES2023", "DOM", "DOM.Iterable"]`, `jsx: "react-jsx"`, `allowJs: false`, `incremental: true`, `plugins: [{ "name": "next" }]` |
| `packages/config/tsconfig/library.json` | create | extends base; `types: ["node"]` |
| `packages/config/eslint/base.js` | create | Flat config array: `@eslint/js` recommended; `typescript-eslint` `recommended` for `**/*.{ts,tsx,mts}` (keeps `@typescript-eslint/no-explicit-any` as an error, constraint T1); for `**/*.{js,mjs}` Node globals declared inline (`process`, `console`, `URL`: readonly), so the `globals` package isn't needed; ignores `**/node_modules/**`, `**/.next/**`, `**/.turbo/**`, `**/coverage/**` |
| `packages/config/eslint/next.js` | create | base + `eslint-config-next/core-web-vitals` + `eslint-config-next/typescript` (the Next 16 flat-config entry points; they include `jsx-a11y`), ignores `.next/**`, `next-env.d.ts`, `test-results/**`, `playwright-report/**` |
| `packages/tokens/package.json` | create | `name: "@tunehold/tokens"`, `private`, `type: "module"`, `exports: { ".": "./src/index.ts", "./theme.css": "./src/generated/theme.css" }`. Scripts: `generate: node scripts/generate.mjs`, `lint: eslint .`, `typecheck: tsc --noEmit`, `test: vitest run`. devDependencies: `@tunehold/config` (`workspace:*`), `eslint`, `typescript`, `vitest`, `vite`, `@types/node` (catalog) |
| `packages/tokens/tsconfig.json` | create | extends `@tunehold/config/tsconfig/library.json`; `include: ["src"]` |
| `packages/tokens/eslint.config.mjs` | create | `export { default } from '@tunehold/config/eslint/base'` (or a spread of it) |
| `packages/tokens/scripts/generate.mjs` | create | Reads `../../../replica/design/tokens.json` (resolved from `import.meta.url`) and writes `src/generated/tokens.ts` and `src/generated/theme.css` with the mapping in Contracts. With `--check`, it writes nothing and exits 1 if either file differs from what it would write. Output is deterministic (stable key order, LF, final newline). Each file starts with a comment saying it is generated from `replica/design/tokens.json` by this script and must not be edited by hand |
| `packages/tokens/src/generated/tokens.ts` | create (generated) | `export const tokens = { … } as const` (shape in Contracts) |
| `packages/tokens/src/generated/theme.css` | create (generated) | Tailwind v4 `@theme` block plus the `[data-theme]` scopes (Contracts) |
| `packages/tokens/src/index.ts` | create | Re-exports `tokens` and the derived types `ColorRole`, `TypeStep`, `Tokens` |
| `packages/tokens/src/tokens.test.ts` | create | (1) `tokens.color`, `tokens.colorLight`, `font`, `type`, `space`, `radius`, `shadow` and `motion` deep-equal the matching blocks of `replica/design/tokens.json`, read with `node:fs`. (2) Both colour blocks have the same 12 role keys. (3) `node scripts/generate.mjs --check`, run with `child_process.spawnSync(process.execPath, …)`, exits 0 |
| `apps/web/package.json` | create | `name: "@tunehold/web"`, `private`, `type: "module"`. Scripts: `dev: next dev`, `build: next build`, `start: next start`, `lint: eslint .`, `typecheck: next typegen && tsc --noEmit`, `test: vitest run`, `e2e: playwright test`. dependencies: `next`, `react`, `react-dom`, `@tunehold/tokens` (`workspace:*`). devDependencies: `@tunehold/config` (`workspace:*`), `tailwindcss`, `@tailwindcss/postcss`, `postcss`, `@playwright/test`, `vitest`, `vite`, `eslint`, `typescript`, `@types/node`, `@types/react`, `@types/react-dom` |
| `apps/web/tsconfig.json` | create | extends `@tunehold/config/tsconfig/nextjs.json`; `types: ["node"]`; `include: ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"]`; `exclude: ["node_modules"]`. Accept the edits `next build` makes to this file and commit them. No `@/*` alias in M0 (it would need repeating in the Vitest config); use relative imports |
| `apps/web/next.config.ts` | create | `transpilePackages: ['@tunehold/tokens']`, `poweredByHeader: false`, `reactStrictMode: true`. Nothing else (no `cacheComponents`, because the route segment configs below rely on it being off) |
| `apps/web/postcss.config.mjs` | create | `export default { plugins: { '@tailwindcss/postcss': {} } }` |
| `apps/web/eslint.config.mjs` | create | the `@tunehold/config/eslint/next` preset |
| `apps/web/vitest.config.ts` | create | `defineConfig` from `vitest/config`: `test.environment: 'node'`, `test.include: ['app/**/*.test.ts', 'src/**/*.test.ts']` (so `e2e/` is never picked up) |
| `apps/web/playwright.config.ts` | create | `testDir: './e2e'`, `forbidOnly: !!process.env.CI`, `retries: 0`, reporter `list` (plus `github` when `CI` is set; no HTML report, see Risks), `use.baseURL: 'http://127.0.0.1:3100'`, `trace: 'retain-on-failure'`, one project `chromium` (`devices['Desktop Chrome']`, no `channel`). `webServer: { command: 'pnpm build && pnpm start -p 3100', url: 'http://127.0.0.1:3100/api/v1/health', reuseExistingServer: !process.env.CI, timeout: 240_000 }` |
| `apps/web/vercel.json` | create | `{ "$schema": "https://openapi.vercel.sh/vercel.json", "regions": ["iad1"] }`. The daily cron comes in 1a |
| `apps/web/app/layout.tsx` | create | Root layout. `Atkinson_Hyperlegible_Next` from `next/font/google`: variable font (no `weight`, the `wght` axis 200–800 covers 400/600/700), `subsets: ['latin', 'latin-ext']`, `display: 'swap'`, `variable: '--tunehold-font-sans'`. `<html lang="en" className={font.variable}>`: the variable must sit on `<html>` (see Contracts, fonts). `<body className="bg-bg font-sans text-base text-text antialiased">`. Imports `./globals.css`. `metadata.title` default `Tunehold` |
| `apps/web/app/globals.css` | create | `@import "tailwindcss";` `@import "@tunehold/tokens/theme.css";` then an app-level `@theme` with `--container-content: 70rem` (landing.md: content at most 1120px) and `--breakpoint-wide: 68.75rem` (landing.md: 3 card columns above about 1100px). A focus rule for links, buttons and `[tabindex]`: on `:focus-visible`, `outline: 2px solid var(--color-accent); outline-offset: 2px`, never removed. `@media (prefers-reduced-motion: no-preference) { html { scroll-behavior: smooth; } }`. No hex values |
| `apps/web/app/icon.svg` | create | 32×32: a `#100E17` square with a plain "T" in `#AC9CFA`, drawn as paths, not text. This is the one file in `apps/web` allowed to hold hex values, because a favicon can't read CSS variables. Replace it once the logo brief's favicon set exists |
| `apps/web/app/(marketing)/page.tsx` | create | `export const dynamic = 'force-static'`; `export const metadata` (Contracts, Metadata); composes the sections below in the order of the Build notes table |
| `apps/web/app/api/v1/health/route.ts` | create | The health route (Contracts) |
| `apps/web/app/api/v1/health/route.test.ts` | create | Vitest: 200; body equals `{ ok: true, version: 'dev' }` with `VERCEL_GIT_COMMIT_SHA` unset; `{ ok: true, version: 'abc1234' }` with it stubbed to `abc1234def567890` (`vi.stubEnv`); `Cache-Control` is `no-store`; `Content-Type` starts with `application/json` |
| `apps/web/src/marketing/copy.ts` | create | Every string the page renders, typed as in Contracts. Nothing else (no ids, no class names) |
| `apps/web/src/marketing/status.ts` | create | `featureStatus` and `loginAvailable` (Contracts) |
| `apps/web/src/marketing/copy.test.ts` | create | The verbatim check (Contracts, "Copy check"), plus: `featureStatus.length === copy.features.cards.length`, and the tuple lengths 3/3/8/9/8 |
| `apps/web/src/marketing/components/site-header.tsx` | create | `<header>`, dark band: wordmark link (`href="#top"`, text "Tunehold", bold, at least 44×44px target). Renders the "Log in" link to `/login` only when `loginAvailable` |
| `apps/web/src/marketing/components/hero.tsx` | create | `<section id="top">`, dark band: `h1`, lead line, `HowItWorksLink`, small print, `ScreenshotMock`. Text left and mock right from `lg`; one column below that, with the mock under the text |
| `apps/web/src/marketing/components/how-it-works-link.tsx` | create | `'use client'`. `<a href="#how-it-works">` styled as the primary button (`bg-accent text-on-accent rounded-md min-h-11`). On click it doesn't call `preventDefault`: it calls `document.getElementById('how-it-works-title')?.focus({ preventScroll: true })` and lets the browser follow the link, so the CSS smooth scroll (or the instant jump under reduced motion) still applies. It works as a plain link without JS |
| `apps/web/src/marketing/components/screenshot-mock.tsx` | create | `<figure>` with a `div role="img" aria-label={copy.hero.mockAlt}` whose children are `aria-hidden` blocks: a sidebar, an album grid of plain squares in `bg-surface` and `bg-surface-raised`, and a player bar. Token classes of the dark band only. No words, no gradients, no green, no device frame, nothing shaped like the original's UI. `<figcaption>` with `copy.hero.mockCaption` in `text-sm text-text-muted`. Fluid width (no fixed px), so 320px never scrolls sideways |
| `apps/web/src/marketing/components/problem-section.tsx` | create | `<section id="problem">`, `h2`, then a `ul` of 3 items (bold title, then body) |
| `apps/web/src/marketing/components/how-it-works-section.tsx` | create | `<section id="how-it-works">`, `<h2 id="how-it-works-title" tabIndex={-1}>`, intro line, then an `ol` of 3 steps (bold title, then body) |
| `apps/web/src/marketing/components/features-section.tsx` | create | `<section id="features">`, `h2`, intro line, 8 cards (`h3`, body, status tag) in a grid: 1 column, 2 from `md`, 3 from `wide`. Cards: `bg-surface rounded-lg` (`shadow-card` optional). Status tag: "In progress" in `text-sm text-text-muted`, or "Works today" in `text-sm text-success` with an `aria-hidden` tick (the text is always present). Then the "Also part of the build:" line with its 9 items |
| `apps/web/src/marketing/components/faq-section.tsx` | create | `<section id="faq">`, `h2`, then each question as `h3` with its answer as `p`, all visible (no accordion) |
| `apps/web/src/marketing/components/final-cta.tsx` | create | `<section id="start">`, `h2`. With `loginAvailable`: the line and a "Log in" button-styled link to `/login` (`bg-accent text-on-accent`). Without it (M0): only `copy.finalCta.lineWithoutLogin` |
| `apps/web/src/marketing/components/site-footer.tsx` | create | `<footer>` on `bg-surface` in the light theme: the wordmark (text, not a link) and `copy.footer.statusLine` |
| `apps/web/e2e/landing.spec.ts` | create | Landing e2e (Acceptance criteria AC6–AC11, AC14) |
| `apps/web/e2e/health.spec.ts` | create | `GET /api/v1/health` against the built app (AC12) |
| `replica/build-log.md` | create | Header plus one line: `S01 · 2026-10-xx · done · landing page (milestone 0); "Log in" hidden until /login exists (1a); mock in the screenshot slot until the app runs` |

After the merge, the orchestrator moves the M0 commands in `.claude/workflow/context/project.md` from "planned" to "available" (including `pnpm --filter @tunehold/web e2e` and `pnpm brand-gate`). The developer doesn't edit `project.md`.

## Contracts

### Package names and workspace scripts

| package | path | scripts (all exist after M0) |
| --- | --- | --- |
| `tunehold` (root) | `/` | `dev`, `lint`, `typecheck`, `test`, `build`, `format`, `brand-gate` |
| `@tunehold/config` | `packages/config` | none |
| `@tunehold/tokens` | `packages/tokens` | `generate`, `lint`, `typecheck`, `test` |
| `@tunehold/web` | `apps/web` | `dev`, `build`, `start`, `lint`, `typecheck`, `test`, `e2e` |

### Dependencies (versions read from the npm registry on 2026-10-05; pin them exactly, no `^` or `~`)

Approved in `architecture.md`:

| package | version | where | note |
| --- | --- | --- | --- |
| `next` | 16.3.8 | web | current `latest` |
| `react`, `react-dom` | 19.3.0 | web | |
| `tailwindcss` | 4.3.3 | web (dev) | |
| `@playwright/test` | **1.56.1** | web (dev) | Not `latest` (1.63.0). 1.56.1 is the release whose `browsers.json` names `chromium` 1194, `chromium-headless-shell` 1194 and `ffmpeg` 1011, exactly what `/opt/pw-browsers` holds. Any other version would look for browsers that aren't there |
| `typescript` | **6.0.3** | root, config (peer), tokens, web (dev) | Not `latest` (7.0.2). TS 7 is the native compiler, and `typescript-eslint` 8.71.0 requires `typescript >=4.8.4 <6.1.0`. 6.0.3 is the newest 6.0.x |
| `turbo` | 2.11.7 | root (dev) | |
| `eslint` | **9.39.5** | config (peer), tokens, web (dev) | Not `latest` (10.12.0). `eslint-config-next` 16.3.8 pulls `eslint-plugin-react` 7.37.5 (peer `eslint ^3 … ^9.7`) and `eslint-plugin-import` 2.32.0 (peer up to `^9`). 9.39.5 is ESLint's `maintenance` tag |
| `prettier` | 3.9.9 | root (dev) | |
| `vitest` | 5.0.3 | tokens, web (dev) | engines Node `^22.12.0` |
| `zod` | — | — | approved but not needed in M0 |

Not in the approved table, needed for M0 (they need the founder's approval, see OPEN 1):

| package | version | where | why |
| --- | --- | --- | --- |
| `@tailwindcss/postcss` | 4.3.3 | web (dev) | Tailwind v4's integration with Next.js (same project as `tailwindcss`) |
| `postcss` | 8.5.28 | web (dev) | Installed alongside `@tailwindcss/postcss` in Tailwind's official Next.js setup |
| `vite` | 8.3.2 | tokens, web (dev) | A required (non-optional) peer dependency of `vitest` 5.0.3 |
| `eslint-config-next` | 16.3.8 (matches `next`) | config | Next.js's official lint rules, including `jsx-a11y` (supports constraint T7). It pulls `@next/eslint-plugin-next`, `eslint-plugin-react`, `-react-hooks`, `-jsx-a11y`, `-import` and `typescript-eslint` |
| `typescript-eslint` | 8.71.0 | config | TypeScript rules for ESLint, including `no-explicit-any` (constraint T1) |
| `@eslint/js` | 9.39.5 | config | ESLint's recommended core rules (a separate package since ESLint 9) |
| `@types/node` | 22.20.5 | tokens, web (dev) | Node 22 types. Confirm it is still the highest 22.x with `pnpm view @types/node@22 version` |
| `@types/react`, `@types/react-dom` | 19.3.0 | web (dev) | React types for strict TS |
| pnpm | 12.9.1 | `packageManager` | The workspace tool named in the stack; current `latest` |
| GitHub Actions `actions/checkout`, `actions/setup-node`, `pnpm/action-setup` | current major at implementation time | `ci.yml` | `pnpm/action-setup` is third-party, so pin it by full commit SHA with the version in a comment |

Put `typescript`, `eslint`, `vitest`, `vite` and `@types/node` in the pnpm `catalog:` and reference them as `"catalog:"`. Not added: `@axe-core/playwright` (axe scans). M0 uses hand-written accessibility checks instead (AC10). It's a candidate for 1a.

### Health route

```ts
// apps/web/app/api/v1/health/route.ts
// GET /api/v1/health — public (no auth), no database or network call. Liveness for deploy checks.
export const dynamic = 'force-dynamic'; // a live function response, never a prerendered file

export type HealthResponse = {
  ok: true;
  version: string; // first 7 characters of VERCEL_GIT_COMMIT_SHA (Vercel system variable); "dev" when unset
};

export function GET(): Response; // 200, Response.json(body), header Cache-Control: no-store
```

- Errors: none of its own. Other methods get the framework's `405` with an `Allow` header. `HEAD` is derived from `GET` by Next.js.
- When `packages/contract` arrives (1a), `HealthResponse` moves there as a zod schema, and the shape doesn't change.

### Environment variables

| name | where | required | what |
| --- | --- | --- | --- |
| `VERCEL_GIT_COMMIT_SHA` | web (runtime) | no | A Vercel system variable that Vercel sets. Read only by the health route |
| `PLAYWRIGHT_BROWSERS_PATH` | the developer's shell | for e2e in this container | `/opt/pw-browsers`. Never `playwright install` here |
| `NODE_USE_ENV_PROXY`, `HTTPS_PROXY`, `NODE_EXTRA_CA_CERTS` | the developer's shell | only behind a proxy | Lets `next build` fetch the font (see Risks). Passed through turbo by `globalPassThroughEnv` |
| `NEXT_TELEMETRY_DISABLED`, `TURBO_TELEMETRY_DISABLED` | `ci.yml` | no | `1` |

No secrets. Nothing goes in Vercel's environment for M0.

### Tokens: TS export (`@tunehold/tokens`)

```ts
export type ColorRole =
  | 'bg' | 'surface' | 'surface-raised' | 'border' | 'border-input' | 'text'
  | 'text-muted' | 'accent' | 'on-accent' | 'accent-2' | 'danger' | 'success';
export type TypeStep = 'xs' | 'sm' | 'base' | 'lg' | 'xl' | 'display';

export const tokens = {
  color: { /* = tokens.json "color" (dark; the app default) */ },
  colorLight: { /* = tokens.json "color-light" (landing body) */ },
  font: { sans: '…', mono: '…' },                    // = "font"
  type: { xs: { size: 12, line: 16, weight: 500 }, /* … */ }, // = "type" (px numbers)
  space: [0, 4, 8, 12, 16, 24, 32, 48, 64],           // = "space"
  radius: { sm: 6, md: 10, lg: 16, pill: 999 },       // = "radius" (px numbers)
  shadow: { card: '…', pop: '…' },                    // = "shadow"
  motion: { fast: '120ms', base: '200ms', ease: 'cubic-bezier(.2,.8,.2,1)' }, // = "motion"
} as const satisfies { color: Record<ColorRole, string>; colorLight: Record<ColorRole, string> /* … */ };
export type Tokens = typeof tokens;
```

`_about`, `_roles` and `pairs` aren't exported. Values are copied as they are, with no case changes to hex strings.

### Tokens: Tailwind v4 theme (`@tunehold/tokens/theme.css`)

| tokens.json | generated CSS | utilities the web uses |
| --- | --- | --- |
| — | `@theme { --color-*: initial; … }`, which removes Tailwind's default palette so only token colours exist | — |
| `color.<role>` | `--color-<role>: <hex>` inside `@theme` (dark is the default, because the app is dark first) | `bg-bg`, `bg-surface`, `bg-surface-raised`, `text-text`, `text-text-muted`, `bg-accent`, `text-on-accent`, `text-success`, `border-border` |
| `color.<role>` again | `:root, [data-theme="dark"] { color-scheme: dark; --color-<role>: <hex>; … }` | `data-theme="dark"` on a band |
| `color-light.<role>` | `[data-theme="light"] { color-scheme: light; --color-<role>: <hex>; … }` | `data-theme="light"` on a band |
| `font.sans` | `--font-sans: var(--tunehold-font-sans, "Atkinson Hyperlegible Next"), system-ui, -apple-system, Segoe UI, Roboto, sans-serif` (the token's first family wrapped in the variable, the rest of the token's list kept) | `font-sans` |
| `font.mono` | `--font-mono: var(--tunehold-font-mono, "Atkinson Hyperlegible Mono"), ui-monospace, SFMono-Regular, Menlo, monospace` | `font-mono` (unused in M0) |
| `type.<step>` | `--text-<step>: <size/16>rem; --text-<step>--line-height: <line/16>rem; --text-<step>--font-weight: <weight>` | `text-xs` … `text-xl`, `text-display` |
| `space` | `--spacing: 0.25rem`. Every `space` value is a multiple of 4px, so `p-1`=4, `p-2`=8, `p-3`=12, `p-4`=16, `p-6`=24, `p-8`=32, `p-12`=48, `p-16`=64 | spacing utilities, using only those steps |
| `radius.<name>` | `--radius-<name>: <n>px` | `rounded-sm|md|lg|pill` |
| `shadow.<name>` | `--shadow-<name>: <value>` | `shadow-card`, `shadow-pop` |
| `motion` | `--ease-standard: <ease>` in `@theme`; `--motion-fast`, `--motion-base` as plain properties on `:root` | `ease-standard` |

Rules for the web:
- **Fonts.** `next/font` serves the font under a hashed family name and exposes it through `--tunehold-font-sans`. The variable must be set on `<html>` (`:root`), where `--font-sans` is computed. Set on `<body>`, it would silently fall back to system fonts.
- **Text colour in themed bands.** A colour inherited from `<body>` is already computed. Every element that sets `data-theme` must therefore also set its own `bg-*` and `text-text`, or its text keeps the other band's colour.
- **No hex values or arbitrary colour utilities** (`[#…]`) in `apps/web` `.ts`, `.tsx` or `.css`. The only exception is `app/icon.svg`. Sizes come from the type, spacing and radius tokens, plus the two app-level layout constants in `globals.css`.
- If Tailwind doesn't apply `--text-*--font-weight`, add `font-normal`, `font-semibold` or `font-bold` next to the size. AC8 checks the computed weights either way.

### Landing structure (from `landing.md` Build notes)

| order | element | theme | content |
| --- | --- | --- | --- |
| 1 | `<header>` | dark (`bg-bg text-text`) | wordmark link to `#top`, accessible name "Tunehold" (no "Log in" in M0) |
| 2 | `<main>` › `<section id="top">` | dark | `h1`, lead, "See how it works" (link styled as a button), small print (`text-sm text-text-muted`), screenshot mock and caption |
| 3 | `<main>` › `<div data-theme="light" class="bg-bg text-text">`, holding rows 4–7 | light | |
| 4 | `section#problem` | light | `h2` "Owning the files is the easy part", `ul` × 3 |
| 5 | `section#how-it-works` | light | `h2#how-it-works-title[tabindex=-1]` "How it works", intro, `ol` × 3 |
| 6 | `section#features` | light | `h2` "What Tunehold is being built to do", intro, 8 cards (`h3`, body, status tag), "Also part of the build:" + 9 items |
| 7 | `section#start` | light | `h2` "Start with one album", then "Tunehold is in development, for its maker and a few friends." |
| 8 | `<footer data-theme="light">` | light, `bg-surface text-text` | wordmark (text) + status line |

Layout: content at most `max-w-content` (1120px), centred; body text at most `max-w-prose` (65ch). The gutter is `px-4` (16px) on phones and may grow from `md`. Section spacing is `py-12` (48px) on phones and `md:py-16` (64px) on wide screens. Buttons are `rounded-md` and `min-h-11` (44px). Cards are `rounded-lg`. Flat fills only, no gradients. `accent-2` isn't used. The only green is `text-success` on a "Works today" tag, and M0 has none of those.

Colour pairs the page uses (all among the 24 that `contrast.py` checks; the mock is decorative and sits behind its `role="img"` label):
- dark band: `text`/`bg`, `text-muted`/`bg`, `on-accent`/`accent`, and `accent`/`bg` (focus ring, 3:1);
- light band: `text`/`bg`, `text`/`surface`, `text-muted`/`surface` (status tags), `text-muted`/`bg`, and `accent`/`bg` and `accent`/`surface` (focus ring on the focusable heading).

### Copy contract

```ts
// apps/web/src/marketing/copy.ts — every string leaf is a verbatim segment of replica/launch/landing.md
type Item = { readonly title: string; readonly body: string };
type QA = { readonly question: string; readonly answer: string };
type Eight<T> = readonly [T, T, T, T, T, T, T, T];

export const copy: {
  meta: { title: string; description: string; ogTitle: string };
  header: { wordmark: string; logIn: string };
  hero: { headline: string; lead: string; button: string; smallPrint: string; mockAlt: string; mockCaption: string };
  problem: { heading: string; items: readonly [Item, Item, Item] };
  howItWorks: { heading: string; intro: string; steps: readonly [Item, Item, Item] };
  features: { heading: string; intro: string; cards: Eight<Item>; alsoLabel: string; also: readonly [string, string, string, string, string, string, string, string, string] };
  status: { worksToday: string; inProgress: string };
  faq: { heading: string; items: Eight<QA> };
  finalCta: { heading: string; lineWithLogin: string; button: string; lineWithoutLogin: string };
  footer: { wordmark: string; statusLine: string };
};
```

Where each value comes from in `landing.md`:
- `meta.title` and `meta.description` are the backticked values under "Meta and sharing". `meta.ogTitle` is `Tunehold`.
- `hero.headline` is the `#` line. `hero.lead` is the paragraph under it. `hero.button` is "See how it works". `hero.smallPrint` is the small-print line.
- `hero.mockAlt` and `hero.mockCaption` are the quoted alt text and caption under "Screenshot slot".
- `problem`, `howItWorks`, `features` and `faq` come from their sections. A bold lead-in becomes `title` and the text after it becomes `body`. Italic build notes such as `*(U1)*` or `*(F6)*` are never copied.
- `howItWorks.heading` is "How it works" and `faq.heading` is "FAQ". These are the only headings of those two blocks, so they are the `h2`s.
- `status` is the quoted tag texts.
- `finalCta.lineWithoutLogin` is the quoted replacement line under "Call to action".
- `footer.statusLine` is the quoted Footer line.
- The alternative headlines (the italic "Other headlines" list) aren't used.

```ts
// apps/web/src/marketing/status.ts
export type FeatureStatus = 'works-today' | 'in-progress';
/** Same order as copy.features.cards. Flip a card only when the feature works for an invited user on the deployed app. */
export const featureStatus: readonly FeatureStatus[]; // M0: 8 × 'in-progress'
/** true once /login exists (milestone 1a): shows the header "Log in" link and the final "Log in" button. */
export const loginAvailable: boolean; // M0: false
```

### Copy check (`copy.test.ts`)

1. Read `replica/launch/landing.md` from the repo root, resolved from `import.meta.url`.
2. Build its set of **segments**. For each line:
   - strip indentation, leading `#`s and list markers (`- `, `1. `);
   - remove italic build notes matching `\*\([^)]*\)\*`;
   - split on `**`;
   - trim each part and collapse internal whitespace.
   Also add every `"…"`-quoted and every `` `…` ``-backticked substring of every line as its own segment. Drop empty strings.
3. Walk every string leaf of `copy` and assert that it is **exactly equal** to one segment. A shortened sentence or a changed word fails, and so does any string that isn't in `landing.md`.
4. Check the tuple lengths (3 problem items, 3 steps, 8 cards, 9 "also" items, 8 FAQ items) and that `featureStatus` has as many entries as there are cards.

### Metadata (`app/(marketing)/page.tsx`)

```ts
export const metadata: Metadata = {
  title: copy.meta.title,               // "Tunehold: the music you own, on the web, iPhone and Android"
  description: copy.meta.description,
  robots: { index: false },             // renders <meta name="robots" content="noindex">; proposed default, founder's call (OPEN 5)
  openGraph: { title: copy.meta.ogTitle, description: copy.meta.description, type: 'website' },
};
```

No `og:image`, no `metadataBase`, no Twitter card, no analytics. The favicon comes from `app/icon.svg`.

### Hero link behaviour

- It is an `<a href="#how-it-works">`, because it navigates.
- Activating it with a mouse or with Enter:
  - the URL hash becomes `#how-it-works`;
  - `#how-it-works-title` gets focus;
  - the heading ends up in the viewport.
- Under `prefers-reduced-motion: no-preference` the scroll is smooth (CSS). Under `reduce` it is instant.
- Without JS it still jumps to the section.

### CI (`.github/workflows/ci.yml`)

- Triggers: `push` (all branches), `pull_request`, `workflow_dispatch`. Never `pull_request_target`.
- Settings: `permissions: contents: read`; `concurrency: { group: ci-${{ github.ref }}, cancel-in-progress: true }`; `env: { NEXT_TELEMETRY_DISABLED: 1, TURBO_TELEMETRY_DISABLED: 1 }`.
- One job, `ci`, on `ubuntu-latest` with `timeout-minutes: 15`. Steps:
  1. checkout;
  2. `pnpm/action-setup`, which reads `packageManager`;
  3. `actions/setup-node` with `node-version-file: .nvmrc` and `cache: pnpm`;
  4. `pnpm install --frozen-lockfile`;
  5. `pnpm lint`;
  6. `pnpm typecheck`;
  7. `pnpm test`;
  8. `pnpm build`;
  9. `pnpm brand-gate`.
- No secrets and no environments. The repository is public, so Actions minutes are free.

## Tracks

Single track (medium): `frontend-developer` owns every file in the table above. The health route is part of the same track: it is a few lines with no backend dependency.

## Acceptance criteria

The landing page is static and has no data, so it has no empty, loading or error state. S01's recorded states, "default" and "mobile", are covered by AC6–AC9. The health route has no failure path of its own.

- [ ] **AC1 Install.** On Node 22.x with pnpm 12.9.1, `pnpm install` succeeds from a clean clone: no unapproved build-script error, no peer-dependency error, and no browser download. `pnpm install --frozen-lockfile` passes with the committed lockfile.
- [ ] **AC2 Lint.** `pnpm lint` exits 0. It covers Prettier on the whole workspace (minus `.prettierignore`) and ESLint in `apps/web` and `packages/tokens`. A temporary `const x: any = 1` in `apps/web` makes it fail (checked once, not committed).
- [ ] **AC3 Typecheck.** `pnpm typecheck` exits 0 under `strict` in both workspaces, with no `any` and no `@ts-ignore`.
- [ ] **AC4 Unit tests.** `pnpm test` exits 0 and runs at least these: the tokens deep-equal, same-roles and generator `--check` tests; the health route tests; the copy check. Changing one hex value in `packages/tokens/src/generated/theme.css` by hand makes `pnpm test` fail (checked once, reverted).
- [ ] **AC5 Build.** `pnpm build` exits 0. The Next.js build output marks `/` as static (`○`) and `/api/v1/health` as dynamic (`ƒ`).
- [ ] **AC6 E2E runs here.** `PLAYWRIGHT_BROWSERS_PATH=/opt/pw-browsers pnpm --filter @tunehold/web e2e` passes, using `chromium-1194` / `chromium_headless_shell-1194` from `/opt/pw-browsers` and downloading nothing.
- [ ] **AC7 Content and structure** (e2e at 1280×800, strings imported from `copy.ts`):
  - the `<title>` is exact, and `html[lang="en"]` is set;
  - exactly one `header`, one `main` and one `footer`;
  - exactly one `h1`, with `copy.hero.headline`;
  - five `h2`s in this order: problem, how it works, features, FAQ, final;
  - the problem section has a `ul` of 3 items, and how it works has an `ol` of 3;
  - 8 feature `h3`s, each card showing the text "In progress";
  - the 9 "also" items are visible;
  - 8 FAQ `h3`s with their answers visible (no collapsed content);
  - the final section shows `copy.finalCta.lineWithoutLogin`;
  - there is no link or button named "Log in";
  - the footer shows the status line;
  - `getByRole('img', { name: copy.hero.mockAlt })` is visible, and the caption is visible.
- [ ] **AC8 Responsive and type** (e2e):
  - at 320×800, `document.documentElement.scrollWidth <= document.documentElement.clientWidth`, and likewise at 1280×800, and at 1280×800 with the root font size set to 200%;
  - at 320 the `h1` computes to 28px/700, the mock sits below the hero text, and the feature cards are in one column;
  - at 1280 the `h1` computes to 40px/700, the mock sits to the right of the text, and the cards are in 3 columns;
  - `h2` computes to 28px/700, `h3` to 20px/600, and body text to 16px/24px;
  - `body` computes a `font-family` that starts with the next/font family, not `system-ui`.
- [ ] **AC9 CTA** (e2e):
  - Click "See how it works": the URL ends with `#how-it-works`, the "How it works" `h2` is focused (`toBeFocused()`), and it is in the viewport (`toBeInViewport()`).
  - Same result from the keyboard: from page load, Tab reaches the wordmark first and the CTA second, then press Enter.
  - With `emulateMedia({ reducedMotion: 'reduce' })`, the computed `scroll-behavior` of `html` is `auto`. With `'no-preference'`, it is `smooth`.
- [ ] **AC10 Accessibility basics** (e2e, no axe):
  - every `img` has an `alt` attribute, and every link and button has an accessible name;
  - heading levels never skip (h1 → h2 → h3);
  - the wordmark link and the CTA each have a bounding box of at least 44×44px;
  - with the CTA focused from the keyboard, its computed outline is `2px solid rgb(172, 156, 250)` with `outline-offset: 2px`;
  - no `<form>` or `<input>` on the page;
  - no console error and no failed request during load, including the favicon;
  - every request goes to the test server's origin, so there are no third-party requests and the font is self-hosted.
- [ ] **AC11 Metadata** (e2e): `meta[name="robots"]` contains `noindex`; the meta description equals `copy.meta.description`; `og:title` is `Tunehold`; `og:description` equals the description; there is no `og:image`.
- [ ] **AC12 Health** (Vitest and e2e): `GET /api/v1/health` returns 200, with `Content-Type: application/json` and `Cache-Control: no-store`. The body is `{ "ok": true, "version": <string> }`, with `"dev"` locally. `POST` returns 405.
- [ ] **AC13 Tokens wired.**
  - `apps/web` uses token utilities only: `grep -rnE "#[0-9a-fA-F]{3,8}\b|\[#" apps/web/app apps/web/src --include=*.ts --include=*.tsx --include=*.css` prints nothing (`icon.svg` isn't matched).
  - In the e2e, the hero background computes to `rgb(16, 14, 23)` (`#100E17`) and the problem section background to `rgb(251, 250, 254)` (`#FBFAFE`).
- [ ] **AC14 Brand gates.**
  - `pnpm brand-gate` exits 0. It runs the sweep of `apps/web` and `packages` with `--config` (constraint 2's deploy gate), the labels sweep, the Title-case grep, and `contrast.py` on both colour blocks.
  - The e2e asserts that the rendered HTML contains none of `replica/brand.json` `avoid` (case-insensitive), `domains` or `colors`. Test files read those lists from `brand.json` and never write the original's name themselves, because the sweep would flag them.
  - Run from the root, the sweep reports no hit in any file this milestone creates. The only hits allowed are the instruction lines listed in `replica/brand.md` (Sweep).
- [ ] **AC15 No template leftovers.** No `favicon.ico`, `next.svg`, `vercel.svg`, `file.svg`, `globe.svg` or `window.svg`, no Geist font, and no `public/` folder unless something real needs one.
- [ ] **AC16 CI.** `.github/workflows/ci.yml` runs the steps listed in Contracts. After the push that the user approves, the run on `feature/m0-scaffold-landing` is green. This is checked at validation, because the developer never pushes.
- [ ] **AC17 README** exists as described. It never names the original and never mentions any tool that wrote code.
- [ ] **AC18 Authorship.** Every commit is authored as `Juan José Acevedo Otálvaro <178350246+jjacevedo@users.noreply.github.com>`. Subjects are imperative ("Add …"). No attribution trailers.

### Verification (run from the repo root, paste the summarized results)

```bash
pnpm install
pnpm lint
pnpm typecheck
pnpm test
pnpm build
PLAYWRIGHT_BROWSERS_PATH=/opt/pw-browsers pnpm --filter @tunehold/web e2e
pnpm brand-gate
# what brand-gate runs, for the record:
python3 .claude/skills/replica-brand/sweep.py apps/web --config replica/brand.json      # exit 0
python3 .claude/skills/replica-brand/sweep.py packages --config replica/brand.json      # exit 0
python3 .claude/skills/replica-brand/sweep.py apps/web --avoid "Liked Songs,Smart Shuffle,Discover Weekly,Daily Mix"   # exit 0
python3 .claude/skills/replica-brand/sweep.py packages --avoid "Liked Songs,Smart Shuffle,Discover Weekly,Daily Mix"   # exit 0
grep -rnI --exclude-dir=node_modules --exclude-dir=.next "Your Library" apps packages   # no output
python3 .claude/skills/replica-design/contrast.py replica/design/tokens.json            # 24 pairs, 0 failing (dark)
f=$(mktemp) && python3 -c "import json,sys;t=json.load(open('replica/design/tokens.json'));t['color']=t['color-light'];json.dump(t,open(sys.argv[1],'w'))" "$f" && python3 .claude/skills/replica-design/contrast.py "$f"   # 24 pairs, 0 failing (light)
python3 .claude/skills/replica-brand/sweep.py . --config replica/brand.json             # report: only the instruction lines from brand.md#sweep
```

### `features.csv`

There's no row to change. The landing page (S01) has no row in `replica/features.csv`, and the rows about the app's design ("Dark theme UI", "Responsive web layout (desktop sidebar mobile bottom nav)") are about app screens that arrive in 1a and in Area G. `replica/build-log.md` records S01 instead.

## Founder follow-up (after the merge; not part of the developer's work)

Milestone 0 is done when the page is live on `*.vercel.app` (`architecture.md`, Build order 0). These steps are for the founder, in this order:

1. **Rename the GitHub repository first** (Settings → General → Repository name, for example `tunehold`). The current name contains the original's name, and Vercel builds project names and preview URLs from the repository name (`brand.md`, Sweep). Then update the local remote: `git remote set-url origin https://github.com/<owner>/tunehold.git`.
2. Vercel → Add New → Project → Import the renamed repository, on the Hobby plan.
3. Project name `tunehold` (gives `tunehold.vercel.app` if it's free; `APP_ORIGIN` in 1a uses it).
4. Framework preset **Next.js**. Root Directory **`apps/web`**. Keep "Include files outside the root directory in the Build Step" on, because the workspace packages live outside `apps/web`. Keep the default install and build commands.
5. Environment variable `ENABLE_EXPERIMENTAL_COREPACK=1` (all environments), so that Vercel installs with the `packageManager` version (pnpm 12.9.1) instead of guessing from the lockfile.
6. Node.js version **22.x** (Settings → Build and Deployment).
7. Function region **`iad1`** (Washington, D.C.). `apps/web/vercel.json` already pins it, so check that the setting shows it.
8. Production branch: the repository's default branch (today `cl/great-gauss-36g7dv`, the only one). Leave Vercel Authentication on for preview deployments (the Hobby default). Don't enable Web Analytics or Speed Insights, because the landing page has no analytics.
9. Deploy, then check:
   - `https://<project>.vercel.app/` renders the page;
   - `https://<project>.vercel.app/api/v1/health` returns `{"ok":true,"version":"<7-char sha>"}`;
   - by eye: the page title, the favicon, and a link preview (title and description, no image).

## Risks and open decisions

- **Risk: Playwright and browser mismatch.** `/opt/pw-browsers` holds only `chromium-1194`, `chromium_headless_shell-1194` and `ffmpeg-1011`, which is Playwright 1.56.1. → `@playwright/test` is pinned to 1.56.1 exactly, no `channel` is set, and nothing runs `playwright install` here. Upgrading Playwright later needs new browsers in this container.
- **Risk: the newest TypeScript and ESLint don't fit the lint stack.** TypeScript 7.0.2 is the native compiler and `typescript-eslint` caps at `<6.1.0`, and ESLint 10's plugins aren't declared compatible. → TS 6.0.3 and ESLint 9.39.5 are pinned. TS 6 changed defaults (for example `types`), so the presets set every option explicitly. If `tsc` rejects `import './globals.css'` (side-effect import checks), add `declare module '*.css';` in `apps/web/src/types/assets.d.ts`. Don't turn off strictness.
- **Risk: pnpm 12 behaviour** (inherited from pnpm 11):
  - dependency build scripts fail the install unless they are listed in `allowBuilds`;
  - `minimumReleaseAge` defaults to 1 day, so a version published less than a day before install is refused;
  - unknown keys in `pnpm-workspace.yaml` are errors;
  - `.npmrc` holds only auth and registry settings.
  → `allowBuilds` is filled from the first install's report. If a pin is younger than a day, wait rather than lower the setting.
- **Risk: `next/font/google` needs network at build time.** In this container, outbound HTTPS goes through a proxy. Node's `fetch` uses it only with `NODE_USE_ENV_PROXY=1` (Node 22.21+, and the container has 22.22.0), and turbo's strict env mode would otherwise strip the proxy variables. Fonts.googleapis.com was reachable on 2026-10-05. → Build with `NODE_USE_ENV_PROXY=1`, with the pass-through in `turbo.json`. If it still fails, switch to `next/font/local` with the OFL variable font file and `OFL.txt` from the `google/fonts` repository (`ofl/atkinsonhyperlegiblenext/`), committed under `apps/web/src/fonts/`. `landing.md` allows self-hosting. Report the switch. CI and Vercel have direct network access.
- **Risk: the sweep scans everything under `apps/web` and `packages`.** That includes `test-results/` and Playwright reports, which it doesn't skip, and any test that spells the original's name. → Reporter `list` only, and binary trace and screenshot files are skipped by the sweep. Tests read the names from `brand.json`.
- **Risk: Tailwind v4 details.**
  - Whether `--text-*--font-weight` applies (AC8 measures it).
  - Themed bands need their own `text-text`.
  - `--color-*: initial` must stay, so no default palette colour (green included) is ever available.
- **Risk: the turbo cache misses changes to `replica/` files the tests read.** → `globalDependencies` lists them.
- **Risk: Vercel pnpm version.** → `ENABLE_EXPERIMENTAL_COREPACK=1` in the founder checklist.
- **Risk: copy debt.** Card 1 ("If an upload is interrupted, it picks up where it stopped") and card 2 ("a separate, lighter copy for streaming") describe things v1 may not build (`architecture.md` OPEN 14). → They ship verbatim under "In progress", which is what the architecture asks for until the founder decides.
- **Note for 1a.** Next.js 16 renamed `middleware.ts` to `proxy.ts`, and removed `next lint` (this spec already uses the ESLint CLI). The 1a spec should use `proxy.ts` for the CSP and the security headers.
- **Note.** The repository is public. Nothing in M0 is secret, and `.gitignore` excludes `.env*`. GitHub disables scheduled workflows in public repositories after 60 days without activity, which matters from 1a (`sweep.yml`, `backup.yml`).
- **OPEN 1: dependency approval.** Approve the packages in "Not in the approved table" (`@tailwindcss/postcss`, `postcss`, `vite`, `eslint-config-next`, `typescript-eslint`, `@eslint/js`, `@types/node`, `@types/react`, `@types/react-dom`, pnpm 12.9.1, and the three GitHub Actions). Also approve the deliberate non-`latest` pins: `@playwright/test` 1.56.1, `typescript` 6.0.3, `eslint` 9.39.5. Without approval the developer reports BLOCKED (process constraint 4).
- **OPEN 2: health response shape.** This spec follows `architecture.md`: `{ ok: true, version }`. The task brief said `{ status: 'ok' }`. Confirm the architecture shape, or ask for the other one (then both this spec and `architecture.md` change).
- **OPEN 3: e2e in CI now or in 1a.** The proposed default is 1a, matching the M0 CI list in `architecture.md`. Adding it now costs one job (`playwright install --with-deps chromium` on the runner, about 1–2 minutes, free on a public repository).
- **OPEN 4: Open Graph image.** The proposed default is none until the logo brief's lockup exists. The alternative is a text-only 1200×630 image now, through `next/og` (built into Next.js, no new package): the "Tunehold" wordmark and the line on `#100E17`, which needs `metadataBase` set to the Vercel URL.
- **OPEN 5: `noindex`** (`landing.md` and `architecture.md` OPEN 14 leave it to the founder). The proposed default is on. It's reversible in one line.
- **OPEN 6: licence for the public repository.** There is no `LICENSE` file, so all rights are reserved by default. Choosing a licence belongs to the deferred legal work (`deferred.md`). The proposed default is to add none in M0.
