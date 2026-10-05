// Generated from replica/design/tokens.json by packages/tokens/scripts/generate.mjs.
// Do not edit by hand: change the JSON, then run `pnpm --filter @tunehold/tokens generate`.

export type ColorRole =
  | 'bg'
  | 'surface'
  | 'surface-raised'
  | 'border'
  | 'border-input'
  | 'text'
  | 'text-muted'
  | 'accent'
  | 'on-accent'
  | 'accent-2'
  | 'danger'
  | 'success';

export type TypeStep =
  | 'xs'
  | 'sm'
  | 'base'
  | 'lg'
  | 'xl'
  | 'display';

type TypeToken = { readonly size: number; readonly line: number; readonly weight: number };

export const tokens = {
  color: {
    bg: '#100E17',
    surface: '#18151F',
    'surface-raised': '#221E2C',
    border: '#363042',
    'border-input': '#ADA7BC',
    text: '#F3F1F8',
    'text-muted': '#ADA7BC',
    accent: '#AC9CFA',
    'on-accent': '#140F2E',
    'accent-2': '#FFB48C',
    danger: '#FF8F84',
    success: '#A9D88B',
  },
  colorLight: {
    bg: '#FBFAFE',
    surface: '#F2F0F8',
    'surface-raised': '#FFFFFF',
    border: '#DAD6E6',
    'border-input': '#595369',
    text: '#17141F',
    'text-muted': '#595369',
    accent: '#5E3DCB',
    'on-accent': '#FFFFFF',
    'accent-2': '#A2481A',
    danger: '#BC2F28',
    success: '#3C7420',
  },
  font: {
    sans: '"Atkinson Hyperlegible Next", system-ui, -apple-system, Segoe UI, Roboto, sans-serif',
    mono: '"Atkinson Hyperlegible Mono", ui-monospace, SFMono-Regular, Menlo, monospace',
  },
  type: {
    xs: { size: 12, line: 16, weight: 500 },
    sm: { size: 14, line: 20, weight: 400 },
    base: { size: 16, line: 24, weight: 400 },
    lg: { size: 20, line: 28, weight: 600 },
    xl: { size: 28, line: 34, weight: 700 },
    display: { size: 40, line: 44, weight: 700 },
  },
  space: [0, 4, 8, 12, 16, 24, 32, 48, 64],
  radius: { sm: 6, md: 10, lg: 16, pill: 999 },
  shadow: {
    card: '0 1px 2px rgba(16,24,40,.06), 0 1px 3px rgba(16,24,40,.10)',
    pop: '0 12px 32px rgba(16,24,40,.16)',
  },
  motion: {
    fast: '120ms',
    base: '200ms',
    ease: 'cubic-bezier(.2,.8,.2,1)',
  },
} as const satisfies {
  color: Record<ColorRole, string>;
  colorLight: Record<ColorRole, string>;
  font: Record<string, string>;
  type: Record<TypeStep, TypeToken>;
  space: readonly number[];
  radius: Record<string, number>;
  shadow: Record<string, string>;
  motion: Record<string, string>;
};

export type Tokens = typeof tokens;
