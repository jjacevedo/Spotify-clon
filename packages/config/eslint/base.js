// Shared ESLint flat config for every Tunehold workspace.
import js from '@eslint/js';
import tseslint from 'typescript-eslint';

const tsFiles = ['**/*.{ts,tsx,mts}'];

/** @type {import('eslint').Linter.Config[]} */
const config = [
  {
    ignores: ['**/node_modules/**', '**/.next/**', '**/.turbo/**', '**/coverage/**'],
  },
  js.configs.recommended,
  // `recommended` keeps @typescript-eslint/no-explicit-any as an error (constraint T1).
  ...tseslint.configs.recommended.map((entry) => ({ ...entry, files: tsFiles })),
  {
    // Plain Node scripts and config files. Globals are declared here so the
    // `globals` package isn't needed.
    files: ['**/*.{js,mjs}'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: {
        process: 'readonly',
        console: 'readonly',
        URL: 'readonly',
      },
    },
  },
];

export default config;
