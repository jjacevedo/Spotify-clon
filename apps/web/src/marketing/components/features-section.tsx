import { copy } from '../copy';
import { featureStatus, type FeatureStatus } from '../status';

function StatusTag({ status }: { status: FeatureStatus }) {
  if (status === 'works-today') {
    return (
      <p className="mt-4 inline-flex items-center gap-1 text-sm text-success">
        <svg
          aria-hidden="true"
          viewBox="0 0 16 16"
          className="size-4 shrink-0"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <path d="M3 8.5l3 3 7-7" />
        </svg>
        {copy.status.worksToday}
      </p>
    );
  }
  return <p className="mt-4 text-sm text-text-muted">{copy.status.inProgress}</p>;
}

export function FeaturesSection() {
  return (
    <section id="features" className="mx-auto w-full max-w-content px-4 pt-12 md:px-8 md:pt-16">
      <h2 className="text-xl font-bold">{copy.features.heading}</h2>
      <p className="mt-4 max-w-prose text-base">{copy.features.intro}</p>
      <ul className="mt-8 grid gap-6 md:grid-cols-2 wide:grid-cols-3">
        {copy.features.cards.map((card, index) => (
          <li key={card.title} className="flex flex-col rounded-lg bg-surface p-6 shadow-card">
            <h3 className="text-lg font-semibold">{card.title}</h3>
            <p className="mt-2 flex-1 text-base">{card.body}</p>
            <StatusTag status={featureStatus[index] ?? 'in-progress'} />
          </li>
        ))}
      </ul>
      <div className="mt-12">
        <p className="text-base font-bold">{copy.features.alsoLabel}</p>
        <ul className="mt-4 grid list-inside list-disc gap-2 text-base md:grid-cols-2 wide:grid-cols-3">
          {copy.features.also.map((item) => (
            <li key={item}>{item}</li>
          ))}
        </ul>
      </div>
    </section>
  );
}
