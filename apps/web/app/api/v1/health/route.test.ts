import { afterEach, describe, expect, it, vi } from 'vitest';
import { GET } from './route';

describe('GET /api/v1/health', () => {
  afterEach(() => {
    vi.unstubAllEnvs();
  });

  it('returns 200 with { ok: true, version: "dev" } when no commit SHA is set', async () => {
    vi.stubEnv('VERCEL_GIT_COMMIT_SHA', undefined);
    const response = GET();
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({ ok: true, version: 'dev' });
  });

  it('reports the first 7 characters of the commit SHA', async () => {
    vi.stubEnv('VERCEL_GIT_COMMIT_SHA', 'abc1234def567890');
    const response = GET();
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({ ok: true, version: 'abc1234' });
  });

  it('is JSON and never cached', () => {
    const response = GET();
    expect(response.headers.get('Cache-Control')).toBe('no-store');
    expect(response.headers.get('Content-Type')).toMatch(/^application\/json/);
  });
});
