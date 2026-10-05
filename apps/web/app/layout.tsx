import type { Metadata } from 'next';
import { Atkinson_Hyperlegible_Next } from 'next/font/google';
import type { ReactNode } from 'react';
import './globals.css';

// Variable font: the wght axis (200–800) covers the 400, 600 and 700 the design uses.
// next/font self-hosts it at build time, so the page makes no third-party request.
const sans = Atkinson_Hyperlegible_Next({
  subsets: ['latin', 'latin-ext'],
  display: 'swap',
  variable: '--tunehold-font-sans',
});

export const metadata: Metadata = {
  title: 'Tunehold',
};

export default function RootLayout({ children }: Readonly<{ children: ReactNode }>) {
  return (
    // The font variable must sit on <html>, where the theme computes --font-sans.
    <html lang="en" className={sans.variable}>
      <body className="bg-bg font-sans text-base text-text antialiased">{children}</body>
    </html>
  );
}
