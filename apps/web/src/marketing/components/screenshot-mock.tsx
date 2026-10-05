import { copy } from '../copy';

// A neutral stand-in for the app screenshot, drawn from the dark band's tokens:
// a sidebar, an album grid of plain squares and a player bar. No words and no
// real titles (landing.md, Screenshot slot). Replace it with a real screenshot
// once the app runs, and drop the caption then.
const albumShades = [
  'bg-surface-raised',
  'bg-surface',
  'bg-surface-raised',
  'bg-surface',
  'bg-surface-raised',
  'bg-surface',
] as const;

export function ScreenshotMock() {
  return (
    <figure className="w-full min-w-0">
      <div
        role="img"
        aria-label={copy.hero.mockAlt}
        className="overflow-hidden rounded-lg border border-border bg-bg"
      >
        <div aria-hidden="true" className="flex">
          <div className="flex w-1/4 flex-col gap-3 bg-surface p-3">
            <div className="h-2 w-3/4 rounded-sm bg-surface-raised" />
            <div className="h-2 w-1/2 rounded-sm bg-surface-raised" />
            <div className="h-2 w-2/3 rounded-sm bg-surface-raised" />
            <div className="h-2 w-1/2 rounded-sm bg-surface-raised" />
          </div>
          <div className="grid flex-1 grid-cols-3 gap-2 p-3 md:gap-3 md:p-4">
            {albumShades.map((shade, index) => (
              <div key={index} className="flex flex-col gap-2">
                <div className={`aspect-square w-full rounded-sm ${shade}`} />
                <div className="h-1 w-3/4 rounded-sm bg-surface-raised" />
              </div>
            ))}
          </div>
        </div>
        <div
          aria-hidden="true"
          className="flex items-center gap-3 border-t border-border bg-surface p-3"
        >
          <div className="aspect-square w-8 shrink-0 rounded-sm bg-surface-raised" />
          <div className="flex w-1/4 flex-col gap-2">
            <div className="h-2 w-full rounded-sm bg-surface-raised" />
            <div className="h-1 w-2/3 rounded-sm bg-surface-raised" />
          </div>
          <div className="h-1 flex-1 rounded-pill bg-surface-raised">
            <div className="h-1 w-1/3 rounded-pill bg-accent" />
          </div>
        </div>
      </div>
      <figcaption className="mt-3 text-sm text-text-muted">{copy.hero.mockCaption}</figcaption>
    </figure>
  );
}
