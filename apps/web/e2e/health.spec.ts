import { expect, test } from '@playwright/test';

test.describe('GET /api/v1/health (AC12)', () => {
  test('returns 200 JSON that is never cached', async ({ request }) => {
    const response = await request.get('/api/v1/health');
    expect(response.status()).toBe(200);
    expect(response.headers()['content-type']).toMatch(/^application\/json/);
    expect(response.headers()['cache-control']).toBe('no-store');

    const sha = process.env.VERCEL_GIT_COMMIT_SHA;
    expect(await response.json()).toEqual({ ok: true, version: sha ? sha.slice(0, 7) : 'dev' });
  });

  test('refuses other methods with 405', async ({ request }) => {
    const response = await request.post('/api/v1/health');
    expect(response.status()).toBe(405);
  });
});
