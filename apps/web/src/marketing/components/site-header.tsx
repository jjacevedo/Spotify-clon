import Link from 'next/link';
import { copy } from '../copy';
import { loginAvailable } from '../status';

export function SiteHeader() {
  return (
    <header className="bg-bg text-text">
      <div className="mx-auto flex w-full max-w-content items-center justify-between gap-4 px-4 py-3 md:px-8">
        <a
          href="#top"
          className="inline-flex min-h-11 min-w-11 items-center rounded-sm text-lg font-bold"
        >
          {copy.header.wordmark}
        </a>
        {loginAvailable ? (
          <Link
            href="/login"
            className="inline-flex min-h-11 min-w-11 items-center rounded-sm text-base font-semibold text-accent underline-offset-4 hover:underline"
          >
            {copy.header.logIn}
          </Link>
        ) : null}
      </div>
    </header>
  );
}
