import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  // Workspace packages ship TypeScript source, so Next.js compiles them.
  transpilePackages: ['@tunehold/tokens'],
  poweredByHeader: false,
  reactStrictMode: true,
};

export default nextConfig;
