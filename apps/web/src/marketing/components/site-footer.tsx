import { copy } from '../copy';

export function SiteFooter() {
  return (
    <footer data-theme="light" className="bg-surface text-text">
      <div className="mx-auto w-full max-w-content px-4 py-8 md:px-8">
        <p className="text-lg font-bold">{copy.footer.wordmark}</p>
        <p className="mt-2 max-w-prose text-sm text-text-muted">{copy.footer.statusLine}</p>
      </div>
    </footer>
  );
}
