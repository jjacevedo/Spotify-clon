// Generates src/generated/tokens.ts and src/generated/theme.css from
// replica/design/tokens.json, the single source of Tunehold's design tokens.
//
//   node scripts/generate.mjs          write both files
//   node scripts/generate.mjs --check  write nothing; exit 1 if either file is out of date
//
// Plain Node, no dependencies. The output is deterministic: keys keep the
// order of tokens.json, lines end in LF and each file ends with a newline.
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const SOURCE_LABEL = 'replica/design/tokens.json';
const SCRIPT_LABEL = 'packages/tokens/scripts/generate.mjs';
const SPACING_STEP_PX = 4;
const ROOT_FONT_PX = 16;

const sourceUrl = new URL('../../../replica/design/tokens.json', import.meta.url);
const outDirUrl = new URL('../src/generated/', import.meta.url);
const targets = {
  ts: new URL('tokens.ts', outDirUrl),
  css: new URL('theme.css', outDirUrl),
};

function fail(message) {
  console.error(`tokens: ${message}`);
  process.exit(1);
}

function readTokens() {
  const raw = JSON.parse(readFileSync(sourceUrl, 'utf8'));
  const required = ['color', 'color-light', 'font', 'type', 'space', 'radius', 'shadow', 'motion'];
  for (const key of required) {
    if (!(key in raw)) fail(`${SOURCE_LABEL} has no "${key}" block`);
  }
  const darkRoles = Object.keys(raw.color);
  const lightRoles = Object.keys(raw['color-light']);
  if (darkRoles.join() !== lightRoles.join()) {
    fail(`"color" and "color-light" must list the same roles in the same order`);
  }
  for (const [step, value] of Object.entries(raw.type)) {
    for (const field of ['size', 'line', 'weight']) {
      if (typeof value[field] !== 'number') fail(`type.${step}.${field} must be a number`);
    }
  }
  for (const value of raw.space) {
    if (typeof value !== 'number' || value % SPACING_STEP_PX !== 0) {
      fail(`every space value must be a multiple of ${SPACING_STEP_PX}px (found ${value})`);
    }
  }
  for (const [name, value] of Object.entries(raw.radius)) {
    if (typeof value !== 'number') fail(`radius.${name} must be a number`);
  }
  if (typeof raw.motion.ease !== 'string') fail('motion.ease must be a string');
  return raw;
}

// --- TypeScript -------------------------------------------------------------

function tsString(value) {
  return `'${String(value).replace(/\\/g, '\\\\').replace(/'/g, "\\'")}'`;
}

function tsKey(key) {
  return /^[A-Za-z_$][\w$]*$/.test(key) ? key : tsString(key);
}

function tsValue(value, indent) {
  if (typeof value === 'number') return String(value);
  if (typeof value === 'string') return tsString(value);
  if (Array.isArray(value)) return `[${value.map((item) => tsValue(item, indent)).join(', ')}]`;
  const entries = Object.entries(value);
  const flat = entries.every(([, v]) => typeof v === 'number');
  if (flat) {
    return `{ ${entries.map(([k, v]) => `${tsKey(k)}: ${tsValue(v, indent)}`).join(', ')} }`;
  }
  const pad = '  '.repeat(indent + 1);
  const lines = entries.map(([k, v]) => `${pad}${tsKey(k)}: ${tsValue(v, indent + 1)},`);
  return `{\n${lines.join('\n')}\n${'  '.repeat(indent)}}`;
}

function union(name, keys) {
  return `export type ${name} =\n${keys.map((key) => `  | ${tsString(key)}`).join('\n')};`;
}

function renderTs(t) {
  const body = {
    color: t.color,
    colorLight: t['color-light'],
    font: t.font,
    type: t.type,
    space: t.space,
    radius: t.radius,
    shadow: t.shadow,
    motion: t.motion,
  };
  return [
    `// Generated from ${SOURCE_LABEL} by ${SCRIPT_LABEL}.`,
    '// Do not edit by hand: change the JSON, then run `pnpm --filter @tunehold/tokens generate`.',
    '',
    union('ColorRole', Object.keys(t.color)),
    '',
    union('TypeStep', Object.keys(t.type)),
    '',
    'type TypeToken = { readonly size: number; readonly line: number; readonly weight: number };',
    '',
    `export const tokens = ${tsValue(body, 0)} as const satisfies {`,
    '  color: Record<ColorRole, string>;',
    '  colorLight: Record<ColorRole, string>;',
    '  font: Record<string, string>;',
    '  type: Record<TypeStep, TypeToken>;',
    '  space: readonly number[];',
    '  radius: Record<string, number>;',
    '  shadow: Record<string, string>;',
    '  motion: Record<string, string>;',
    '};',
    '',
    'export type Tokens = typeof tokens;',
    '',
  ].join('\n');
}

// --- CSS (Tailwind v4 theme) --------------------------------------------------

function rem(px) {
  return `${Number((px / ROOT_FONT_PX).toFixed(4))}rem`;
}

// '"Atkinson Hyperlegible Next", system-ui, …' becomes
// 'var(--tunehold-font-sans, "Atkinson Hyperlegible Next"), system-ui, …', so the
// self-hosted font (next/font sets the variable on <html>) wins when it exists.
function fontStack(key, value) {
  const [first = '', ...rest] = value.split(',').map((part) => part.trim());
  return [`var(--tunehold-font-${key}, ${first})`, ...rest].join(', ');
}

function colorLines(block, pad) {
  return Object.entries(block).map(([role, hex]) => `${pad}--color-${role}: ${hex};`);
}

function renderCss(t) {
  const pad = '  ';
  const theme = [
    `${pad}--color-*: initial;`,
    ...colorLines(t.color, pad),
    '',
    ...Object.entries(t.font).map(
      ([key, value]) => `${pad}--font-${key}: ${fontStack(key, value)};`,
    ),
    '',
    ...Object.entries(t.type).flatMap(([step, { size, line, weight }]) => [
      `${pad}--text-${step}: ${rem(size)};`,
      `${pad}--text-${step}--line-height: ${rem(line)};`,
      `${pad}--text-${step}--font-weight: ${weight};`,
    ]),
    '',
    `${pad}--spacing: ${rem(SPACING_STEP_PX)};`,
    '',
    ...Object.entries(t.radius).map(([name, px]) => `${pad}--radius-${name}: ${px}px;`),
    '',
    ...Object.entries(t.shadow).map(([name, value]) => `${pad}--shadow-${name}: ${value};`),
    '',
    `${pad}--ease-standard: ${t.motion.ease};`,
  ];
  const motion = Object.entries(t.motion)
    .filter(([key]) => key !== 'ease')
    .map(([key, value]) => `${pad}--motion-${key}: ${value};`);
  return [
    `/* Generated from ${SOURCE_LABEL} by ${SCRIPT_LABEL}.`,
    '   Do not edit by hand: change the JSON, then run `pnpm --filter @tunehold/tokens generate`. */',
    '',
    '/* Tailwind theme. The dark block is the default, because the app is dark first.',
    '   --color-*: initial removes the default palette, so only token colours exist. */',
    '@theme {',
    ...theme,
    '}',
    '',
    '/* Bands: a [data-theme] element re-points the colour roles for its subtree. */',
    ':root,',
    '[data-theme="dark"] {',
    `${pad}color-scheme: dark;`,
    ...colorLines(t.color, pad),
    '}',
    '',
    '[data-theme="light"] {',
    `${pad}color-scheme: light;`,
    ...colorLines(t['color-light'], pad),
    '}',
    '',
    ':root {',
    ...motion,
    '}',
    '',
  ].join('\n');
}

// --- main ---------------------------------------------------------------------

const tokens = readTokens();
const outputs = [
  [targets.ts, renderTs(tokens)],
  [targets.css, renderCss(tokens)],
];

if (process.argv.includes('--check')) {
  const stale = outputs.filter(([url, content]) => {
    try {
      return readFileSync(url, 'utf8') !== content;
    } catch {
      return true;
    }
  });
  if (stale.length > 0) {
    for (const [url] of stale) {
      console.error(`tokens: ${fileURLToPath(url)} is out of date with ${SOURCE_LABEL}`);
    }
    console.error('tokens: run `pnpm --filter @tunehold/tokens generate` and commit the result');
    process.exit(1);
  }
  console.log('tokens: generated files are up to date');
} else {
  mkdirSync(outDirUrl, { recursive: true });
  for (const [url, content] of outputs) {
    writeFileSync(url, content);
    console.log(`tokens: wrote ${fileURLToPath(url)}`);
  }
}
