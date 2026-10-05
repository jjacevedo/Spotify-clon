import type { Metadata } from 'next';
import { copy } from '../../src/marketing/copy';
import { FaqSection } from '../../src/marketing/components/faq-section';
import { FeaturesSection } from '../../src/marketing/components/features-section';
import { FinalCta } from '../../src/marketing/components/final-cta';
import { Hero } from '../../src/marketing/components/hero';
import { HowItWorksSection } from '../../src/marketing/components/how-it-works-section';
import { ProblemSection } from '../../src/marketing/components/problem-section';
import { SiteFooter } from '../../src/marketing/components/site-footer';
import { SiteHeader } from '../../src/marketing/components/site-header';

// The landing page: static, no data, no forms, no third-party scripts.
export const dynamic = 'force-static';

export const metadata: Metadata = {
  title: copy.meta.title,
  description: copy.meta.description,
  // noindex while the page is only for the founder and friends (landing.md, Meta and sharing).
  robots: { index: false },
  openGraph: {
    title: copy.meta.ogTitle,
    description: copy.meta.description,
    type: 'website',
  },
};

export default function LandingPage() {
  return (
    <>
      <SiteHeader />
      <main>
        <Hero />
        {/* Light band: every element that sets data-theme also sets its own bg and text colour. */}
        <div data-theme="light" className="bg-bg pb-12 text-text md:pb-16">
          <ProblemSection />
          <HowItWorksSection />
          <FeaturesSection />
          <FaqSection />
          <FinalCta />
        </div>
      </main>
      <SiteFooter />
    </>
  );
}
