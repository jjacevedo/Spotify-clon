import { copy } from '../copy';

// Every answer is visible: no accordion (landing.md, Page structure).
export function FaqSection() {
  return (
    <section id="faq" className="mx-auto w-full max-w-content px-4 pt-12 md:px-8 md:pt-16">
      <h2 className="text-xl font-bold">{copy.faq.heading}</h2>
      <div className="mt-8 grid gap-8 md:grid-cols-2">
        {copy.faq.items.map((item) => (
          <div key={item.question} className="max-w-prose">
            <h3 className="text-lg font-semibold">{item.question}</h3>
            <p className="mt-2 text-base">{item.answer}</p>
          </div>
        ))}
      </div>
    </section>
  );
}
