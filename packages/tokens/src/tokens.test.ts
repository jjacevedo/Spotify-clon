import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { tokens } from './index';

const source = JSON.parse(
  readFileSync(new URL('../../../replica/design/tokens.json', import.meta.url), 'utf8'),
) as Record<string, unknown>;

describe('tokens', () => {
  it('match replica/design/tokens.json block by block', () => {
    expect(tokens.color).toEqual(source['color']);
    expect(tokens.colorLight).toEqual(source['color-light']);
    expect(tokens.font).toEqual(source['font']);
    expect(tokens.type).toEqual(source['type']);
    expect(tokens.space).toEqual(source['space']);
    expect(tokens.radius).toEqual(source['radius']);
    expect(tokens.shadow).toEqual(source['shadow']);
    expect(tokens.motion).toEqual(source['motion']);
  });

  it('give both colour blocks the same 12 roles', () => {
    const dark = Object.keys(tokens.color);
    const light = Object.keys(tokens.colorLight);
    expect(dark).toHaveLength(12);
    expect(light).toEqual(dark);
  });

  it('keep the generated files in sync with the JSON (generate.mjs --check)', () => {
    const script = fileURLToPath(new URL('../scripts/generate.mjs', import.meta.url));
    const result = spawnSync(process.execPath, [script, '--check'], { encoding: 'utf8' });
    expect(result.stderr).toBe('');
    expect(result.status).toBe(0);
  });
});
