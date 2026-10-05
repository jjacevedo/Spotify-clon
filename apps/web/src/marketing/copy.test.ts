import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { copy } from './copy';
import { featureStatus } from './status';

const landing = readFileSync(
  new URL('../../../../replica/launch/landing.md', import.meta.url),
  'utf8',
);

const collapse = (text: string) => text.trim().replace(/\s+/g, ' ');

/** Every segment of landing.md that a copy string may equal (spec: "Copy check"). */
function segmentsOf(markdown: string): Set<string> {
  const segments = new Set<string>();
  for (const rawLine of markdown.split('\n')) {
    for (const match of rawLine.matchAll(/"([^"]+)"/g)) segments.add(collapse(match[1] ?? ''));
    for (const match of rawLine.matchAll(/`([^`]+)`/g)) segments.add(collapse(match[1] ?? ''));

    const line = rawLine
      .trim()
      .replace(/^#+\s*/, '')
      .replace(/^(?:- |\d+\. )/, '')
      .replace(/\*\([^)]*\)\*/g, '');
    for (const part of line.split('**')) segments.add(collapse(part));
  }
  segments.delete('');
  return segments;
}

/** Every string leaf of a nested object or tuple, with its path. */
function leaves(value: unknown, path = 'copy'): Array<[string, string]> {
  if (typeof value === 'string') return [[path, value]];
  if (Array.isArray(value)) return value.flatMap((item, i) => leaves(item, `${path}[${i}]`));
  if (value !== null && typeof value === 'object') {
    return Object.entries(value).flatMap(([key, item]) => leaves(item, `${path}.${key}`));
  }
  throw new Error(`${path} is not a string`);
}

describe('landing copy', () => {
  const segments = segmentsOf(landing);
  const strings = leaves(copy);

  it('has string leaves to check', () => {
    expect(strings.length).toBeGreaterThan(50);
  });

  it.each(strings)('%s is verbatim from replica/launch/landing.md', (_path, text) => {
    expect(segments.has(text)).toBe(true);
  });

  it('keeps the section sizes of landing.md', () => {
    expect(copy.problem.items).toHaveLength(3);
    expect(copy.howItWorks.steps).toHaveLength(3);
    expect(copy.features.cards).toHaveLength(8);
    expect(copy.features.also).toHaveLength(9);
    expect(copy.faq.items).toHaveLength(9);
  });

  it('has one status per feature card', () => {
    expect(featureStatus).toHaveLength(copy.features.cards.length);
  });
});
