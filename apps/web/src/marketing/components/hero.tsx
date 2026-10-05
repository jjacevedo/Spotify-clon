import { copy } from '../copy';
import { HowItWorksLink } from './how-it-works-link';
import { ScreenshotMock } from './screenshot-mock';

export function Hero() {
  return (
    <section id="top" className="bg-bg text-text">
      <div className="mx-auto grid w-full max-w-content gap-12 px-4 py-12 md:px-8 md:py-16 lg:grid-cols-2 lg:items-center">
        <div className="min-w-0">
          <h1 className="text-xl font-bold md:text-display">{copy.hero.headline}</h1>
          <p className="mt-4 max-w-prose text-base">{copy.hero.lead}</p>
          <div className="mt-8">
            <HowItWorksLink>{copy.hero.button}</HowItWorksLink>
          </div>
          <p className="mt-4 max-w-prose text-sm text-text-muted">{copy.hero.smallPrint}</p>
        </div>
        <ScreenshotMock />
      </div>
    </section>
  );
}
