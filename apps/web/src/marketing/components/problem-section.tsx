import { copy } from '../copy';

export function ProblemSection() {
  return (
    <section id="problem" className="mx-auto w-full max-w-content px-4 pt-12 md:px-8 md:pt-16">
      <h2 className="text-xl font-bold">{copy.problem.heading}</h2>
      <ul className="mt-8 grid gap-8 lg:grid-cols-3">
        {copy.problem.items.map((item) => (
          <li key={item.title} className="max-w-prose">
            <p className="text-base font-bold">{item.title}</p>
            <p className="mt-2 text-base">{item.body}</p>
          </li>
        ))}
      </ul>
    </section>
  );
}
