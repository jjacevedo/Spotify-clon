// ESLint flat config for Next.js apps: the base preset plus Next.js's own rules
// (core web vitals, TypeScript, and jsx-a11y through eslint-config-next).
import nextVitals from 'eslint-config-next/core-web-vitals';
import nextTypescript from 'eslint-config-next/typescript';
import base from './base.js';

/** @type {import('eslint').Linter.Config[]} */
const config = [
  ...base,
  ...nextVitals,
  ...nextTypescript,
  {
    ignores: ['.next/**', 'next-env.d.ts', 'test-results/**', 'playwright-report/**'],
  },
];

export default config;
