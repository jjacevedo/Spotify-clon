'use client';

import type { ReactNode } from 'react';

// A plain in-page link styled as the primary button. On activation it moves focus
// to the "How it works" heading (landing.md, Accessibility) and lets the browser
// follow the link, so the CSS smooth scroll (or the instant jump under reduced
// motion) still applies. Without JavaScript it is an ordinary jump link.
export function HowItWorksLink({ children }: { children: ReactNode }) {
  function moveFocusToHeading() {
    const heading = document.getElementById('how-it-works-title');
    if (!heading) return;
    const focusHeading = () => heading.focus({ preventScroll: true });
    focusHeading();
    // Chromium clears focus when it follows a link to a fragment whose target can't
    // take focus (the section), which happens after this handler returns. Focus the
    // heading again once the browser has followed the link.
    requestAnimationFrame(() => requestAnimationFrame(focusHeading));
  }

  return (
    <a
      href="#how-it-works"
      onClick={moveFocusToHeading}
      className="inline-flex min-h-11 items-center justify-center rounded-md bg-accent px-6 py-2 text-base font-semibold text-on-accent"
    >
      {children}
    </a>
  );
}
