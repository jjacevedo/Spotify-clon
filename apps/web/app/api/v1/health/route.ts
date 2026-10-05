// GET /api/v1/health — public (no auth), no database or network call. Liveness for deploy checks.
export const dynamic = 'force-dynamic'; // a live function response, never a prerendered file

export type HealthResponse = {
  ok: true;
  version: string; // first 7 characters of VERCEL_GIT_COMMIT_SHA (Vercel system variable); "dev" when unset
};

export function GET(): Response {
  const sha = process.env.VERCEL_GIT_COMMIT_SHA;
  const body: HealthResponse = { ok: true, version: sha ? sha.slice(0, 7) : 'dev' };
  return Response.json(body, { headers: { 'Cache-Control': 'no-store' } });
}
