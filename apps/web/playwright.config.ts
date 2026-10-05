import { defineConfig, devices } from '@playwright/test';

const PORT = 3100;
const baseURL = `http://127.0.0.1:${PORT}`;

// Browsers: @playwright/test is pinned to the release whose Chromium build is
// preinstalled in the dev container (PLAYWRIGHT_BROWSERS_PATH=/opt/pw-browsers).
// On a normal machine, run `pnpm --filter @tunehold/web exec playwright install chromium` once.
export default defineConfig({
  testDir: './e2e',
  forbidOnly: !!process.env.CI,
  retries: 0,
  // No HTML report: the brand sweep scans apps/web, and reports would land in it.
  reporter: process.env.CI ? [['list'], ['github']] : 'list',
  use: {
    baseURL,
    trace: 'retain-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
  webServer: {
    command: `pnpm build && pnpm start -p ${PORT}`,
    url: `${baseURL}/api/v1/health`,
    reuseExistingServer: !process.env.CI,
    timeout: 240_000,
  },
});
