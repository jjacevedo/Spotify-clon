import Link from 'next/link';
import { copy } from '../copy';
import { loginAvailable } from '../status';

// Until /login exists (milestone 1a) the section keeps its heading and shows only
// the no-sign-in line (landing.md, Call to action).
export function FinalCta() {
  return (
    <section id="start" className="mx-auto w-full max-w-content px-4 pt-12 md:px-8 md:pt-16">
      <h2 className="text-xl font-bold">{copy.finalCta.heading}</h2>
      {loginAvailable ? (
        <>
          <p className="mt-4 max-w-prose text-base">{copy.finalCta.lineWithLogin}</p>
          <div className="mt-8">
            <Link
              href="/login"
              className="inline-flex min-h-11 items-center justify-center rounded-md bg-accent px-6 py-2 text-base font-semibold text-on-accent"
            >
              {copy.finalCta.button}
            </Link>
          </div>
        </>
      ) : (
        <p className="mt-4 max-w-prose text-base">{copy.finalCta.lineWithoutLogin}</p>
      )}
    </section>
  );
}
