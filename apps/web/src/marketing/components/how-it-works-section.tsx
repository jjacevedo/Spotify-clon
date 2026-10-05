import { copy } from '../copy';

export function HowItWorksSection() {
  return (
    <section id="how-it-works" className="mx-auto w-full max-w-content px-4 pt-12 md:px-8 md:pt-16">
      {/* tabIndex -1: the "See how it works" link moves focus here after the jump. */}
      <h2 id="how-it-works-title" tabIndex={-1} className="rounded-sm text-xl font-bold">
        {copy.howItWorks.heading}
      </h2>
      <p className="mt-4 max-w-prose text-base">{copy.howItWorks.intro}</p>
      <ol className="mt-8 grid list-inside list-decimal gap-8 marker:font-bold lg:grid-cols-3">
        {copy.howItWorks.steps.map((step) => (
          <li key={step.title} className="max-w-prose">
            <strong className="font-bold">{step.title}</strong>
            <p className="mt-2 text-base">{step.body}</p>
          </li>
        ))}
      </ol>
    </section>
  );
}
