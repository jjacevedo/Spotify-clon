# Tunehold: landing page

Final, 2026-10-04. This is step 1 of `/replica-launch`, rescoped by `replica/deferred.md`.

**What this page is for.** It's a plain presentation page that shows what Tunehold is. Tunehold is at the personal-use stage: it's in development, for the founder and a few friends, and accounts are by invite. The page doesn't sell anything, collect emails or take sign-ups. Visitors read what Tunehold does, and people with an invite log in.

**Skipped on purpose.** These are deferred until a public launch is decided (`replica/deferred.md`):

- **Pricing** (section 5 of the skill's page outline). The page has no prices, plans, payments or "free" wording.
- **Waitlist and email capture**, and the landing-page market test that went with them (the hard gate in `fixes.md` section 6).
- **Store badges.** The iPhone and Android apps reach friends as test builds, not through the stores.
- **Legal pages and links**: terms, privacy and copyright reports.
- Also left out: sharing between accounts (deferred, so not promised here) and any proof section. There are no real users to quote yet, and reviewers' words are research only.

**Sources:**
- `replica/fixes.md`: section 6 (angle A and proof points 1–4), section 4 U1 (owner problems), section 7 ("The problem" rule) and section 5 (F2–F8).
- `replica/recon.md`: flows F01, F02 and F07.
- `replica/brand.md`: voice, vocabulary and bounded wording.
- `replica/features.csv`: the "Also part of the build" line.

**How to read this file.** The copy is in US English, in the brand voice (plain, calm, exact). Everything from "Header" to "Footer" is page copy, except the italic notes in parentheses, which are for the build. Nothing is built yet, so features are described as what Tunehold is being built to do.

---

## Header

**Tunehold** wordmark on the left (links to the top of the page) · **Log in** on the right (a text link, for invited accounts)

## Hero

# The music you own, on the web, iPhone and Android

Bring your CD rips, the albums you bought as files and your own recordings. Tunehold is being built to store each file as you uploaded it and play it in your order, offline on your phone too. No server to set up or keep running.

**Button:** See how it works

**Small print under the button:** In development, for its maker and a few friends. Accounts are by invite.

**Screenshot slot** *(the only image on the page; see Build notes)*

*Other headlines, if the founder prefers:*
- *A home for the music you already own. (This is closest to the angle's wording, so the line under it would carry the practical points.)*
- *Add a folder of your music. Play it on the web, iPhone and Android.*

## The problem

### Owning the files is the easy part

- **A server to look after.** Playing your own files from a server at home means a computer that stays on, software to install and keep updated, and a way to reach it from outside. All of that comes before the first song plays. *(U1)*
- **Uploads that disappeared.** Some music services that stored people's own files have dropped the feature, and at least one deleted every upload that was left. *(F7 market facts, with no service named)*
- **Files spread across devices.** Some albums sit on an old laptop, some on an external drive, a few on your phone. No device has all of it, and a new phone means copying everything again. *(F6 evidence: files kept per device)*

## How it works

This is how Tunehold is being built to work.

1. **Add a folder.** On the web, drop a folder or a few files onto the page. On your phone, pick them. Tunehold reads each file's tags (title, artist, album, track number, cover) and sorts your library by artist and album. You can fix wrong tags in the app. *(F01)*
2. **Press play.** Your library is the same on the web, iPhone and Android. Start an album and keep browsing while it plays. *(F02)*
3. **Listen offline.** Download an album, a playlist or your whole library to your phone, and it plays with no connection. *(F07)*

## Features

### What Tunehold is being built to do

Tunehold is in development. Each card says whether that part works yet.

*(Each card has a status tag, "Works today" or "In progress". On 2026-10-04 every card says "In progress". See Build notes.)*

1. **Add a whole folder** *(F6)*
   Drop in a folder with hundreds of albums. You see what's added and what's left, and you can keep listening while it runs. If an upload is interrupted, it picks up where it stopped. Files already in your library are skipped.

2. **The exact file you added** *(F6)*
   The stored copy is the file you uploaded, bit for bit. Tunehold makes a separate, lighter copy for streaming.

3. **Downloads for offline** *(F5)*
   Download a track, an album, a playlist or your whole library to your iPhone or Android phone. Downloaded tracks play straight from the phone, with or without a connection.

4. **Export on demand** *(F7, the export part only)*
   Get everything out as files you keep: your audio files as you uploaded them, playlists as M3U8 files and your play history as CSV. Playlists and history come first. Audio export follows later in the build.

5. **Shuffle for big collections** *(F4)*
   Shuffle a playlist, the queue or your whole library, even tens of thousands of tracks. Every track in the set plays once before any of them repeats. Shuffle keeps its place when you close the app or switch devices. You can see what's next and reshuffle.

6. **Play counts and smart playlists** *(F8)*
   See how many times you've played each track, and your full listening history. Smart playlists update themselves from rules you set, like genre, year, date added or play count. Search inside a playlist, and jump through long lists from A to Z.

7. **Playlists and queue** *(F2)*
   A playlist or album plays its own tracks in the order you set, and stops at the end. Autoplay stays off unless you turn it on, and then it picks only from your library. Drag to reorder, play next or add to the queue.

8. **Quiet and music-only** *(F3)*
   Your library has no ads, no promotional pop-ups and no prompts to rate the app. Home is built from your library and what you've played. Optional notifications stay off unless you turn them on.

**Also part of the build:**
- search across your library
- album and artist pages built from tags
- tag and cover editing
- M3U and M3U8 playlist import
- picking up on another device where you left off
- gapless playback, repeat and a sleep timer
- lock-screen controls
- keyboard shortcuts on the web
- a dark theme

## FAQ

**Can I sign up?**
Not publicly. Tunehold is in development, for its maker and a few friends, and accounts are by invite. If you have an invite, you create your account on the web. Invited people get the iPhone and Android apps as test builds.

**Does Tunehold come with music?**
No. It has no catalogue and doesn't recommend anything from outside your library. It plays only the files you add, so you use it alongside whatever you already stream.

**What can I add?**
Music you own, as MP3, M4A, FLAC or WAV files: CD rips, albums you bought as files and your own recordings.

**Do I need to run a server?**
No. All you need is a browser or the phone app. Your files are stored in the cloud, so there's no computer at home to leave on.

**Does it work offline?**
It's being built to, on iPhone and Android: anything you've downloaded plays with no connection. The web player needs a connection.

**Can I get my music back out?**
Yes, through export: your audio files as you uploaded them, playlists as M3U8 and play history as CSV. Playlists and history come first in the build, and audio export follows.

**Should I keep my original files?**
Yes. Tunehold is in development, so treat it as a copy you can play on the web and your phone, not your only copy.

**Who can see my library?**
Other people using Tunehold can't see or play your files. Nothing is public, and for now accounts can't share with each other. The person who runs this Tunehold manages the storage your files sit on.

**How much space do I get?**
Each account has a set amount of space, and the app will show how much you've used. If you fill it, everything already in your library keeps playing.

## Final call to action

### Start with one album

Have an invite? Log in, add a folder and press play.

**Button:** Log in

## Footer

The **Tunehold** wordmark and the line "In development, for its maker and a few friends. Accounts are by invite." No legal links, store badges or social icons.

---

## Build notes

For the developer who builds the page. Nothing in this section appears on the page.

### Page structure

The page is a single static HTML file with no forms, accounts or third-party scripts.

| order | block | anchor | theme | contents |
|---|---|---|---|---|
| 1 | Header | | dark band | wordmark (links to `#top`), "Log in" text link |
| 2 | Hero | `#top` | dark band | `h1`, line under it, one button, small print, screenshot slot |
| 3 | The problem | `#problem` | light | `h2` plus three short items |
| 4 | How it works | `#how-it-works` | light | `h2`, intro line, then an ordered list of three steps |
| 5 | Features | `#features` | light | `h2`, intro line, eight cards (`h3`, body, status tag), "Also part of the build" line |
| 6 | FAQ | `#faq` | light | `h2`, then each question as `h3` with its answer as `p`, all visible (no accordion) |
| 7 | Final call to action | `#start` | light | `h2`, one line, one "Log in" button |
| 8 | Footer | | light (`surface`) | wordmark and the status line |

- Wide screens:
  - The hero puts the text on the left and the screenshot slot on the right.
  - Feature cards sit in a 2-column grid (3 columns above about 1100px).
- Phones:
  - Everything is one column, with the screenshot below the hero text and a 16px side gutter.
  - There is no horizontal scroll at 320px.
- Content is at most 1120px wide, and body text is at most about 65 characters per line.
- Spacing comes from `space` in the tokens: 64px between sections on wide screens and 48px on phones.

### Screenshot slot

- **One slot, in the hero.** Later it shows a real screenshot of Tunehold taken from the running app: the web library with the player bar, optionally next to the phone app. Album covers in it are ones the founder made, or plain squares.
- **Until the app exists:**
  - Show a neutral mock drawn from Tunehold's own tokens: a sidebar, an album grid of plain squares in `surface` and `surface-raised` from the `color` block, and a player bar.
  - Use generic labels only. No titles of real albums or artists.
  - Caption it on the page: "Early design. Tunehold is in development."
  - Alt text: "Early design of the Tunehold library: an album grid with a player bar at the bottom."
- **Never:**
  - the original's UI or a layout copied from its screens
  - its green
  - another app's UI
  - device frames that show other brands' screens
  - a mock passed off as the real app
- **When the first build runs**, replace the mock with the screenshot, remove the caption, and rewrite the alt text to describe what the screenshot shows.

### Theme and type

**Two bands, from `replica/design/tokens.json`.** The header and hero use the dark `color` block, and the rest of the page uses `color-light`. The role names are the same in both, so each band reads its own block.

Why the hero is dark:
- The app is dark first, so the real screenshot sits in a band of its own colours, with no bright frame around it.
- The hero matches the Open Graph image and the app icon, which are both on `#100E17`.
- The light body keeps the long reading comfortable, as `brand.md` intends for the landing page.

Token use in each band:
- **Hero (`color`):**
  - `bg` `#100E17`, `text` `#F3F1F8`.
  - Small print in `text-muted` `#ADA7BC` (8.23:1).
  - Button: `accent` `#AC9CFA` with `on-accent` `#140F2E` (7.82:1).
- **Body (`color-light`):**
  - `bg` `#FBFAFE`, `text` `#17141F`.
  - `text-muted` `#595369` for helper text.
  - Links and the final button: `accent` `#5E3DCB`, with `on-accent` `#FFFFFF` on the button (6.99:1).
  - Feature cards on `surface` `#F2F0F8`.
  - Footer on `surface`.

General rules:
- Flat fills only, with no gradients.
- `accent-2` is only for small marks, never a band.
- No green except the `success` status text.
- Optional: if the build adds a dark mode (`prefers-color-scheme: dark`), the light sections switch to the `color` block. It has the same role names and also passes AA.

**Font.** Atkinson Hyperlegible Next, weights 400, 600 and 700. Load it from Google Fonts with `display=swap`, or self-host the OFL files. Fall back to `font.sans` in the tokens.

Type scale:

| element | token | size / line height / weight |
|---|---|---|
| `h1` | `display` (wide screens), `xl` (phones) | 40/44/700, 28/34/700 |
| `h2` | `xl` | 28/34/700 |
| `h3` | `lg` | 20/28/600 |
| body | `base` | 16/24 |
| small print, captions and status tags | `sm` | 14/20 |

**Buttons and cards.**
- Buttons use `radius.md` (10px) and are at least 44px tall.
- Cards use `radius.lg` (16px) and the `card` shadow, or no shadow.

**Logo.** Until the logo from the brief exists, the wordmark is the word "Tunehold" set as text in Atkinson Hyperlegible Next Bold. One word, one capital, no part of it styled on its own.

### Accessibility

- **Contrast (AA).** Both colour blocks passed all 24 pairs on 2026-10-04 (`brand.md`, Contrast). After the page is built, run `python3 .claude/skills/replica-design/contrast.py` on any colour pair the build adds outside those 24, as `/replica-launch` step 1 asks. For the light block, copy `color-light` into `color` in a temporary file first.
- **Structure:**
  - `lang="en"` and one `h1`, then `h2` for each section and `h3` for each card and question.
  - Landmarks: `header`, `main`, `footer`.
  - Steps are an `ol`, and the problem items are a `ul`.
- **Alt text:**
  - The screenshot or mock has alt text as described under Screenshot slot.
  - The wordmark link is labelled "Tunehold".
  - Decorative icons, including the tick on status tags, get `alt=""` or `aria-hidden="true"`.
- **Focus states:**
  - Every link and button shows a 2px `accent` outline with a 2px offset on `:focus-visible`. Use `#AC9CFA` in the dark band and `#5E3DCB` in the light sections. Both are 3:1 or more on their backgrounds.
  - Never remove the outline.
  - Tab order follows the visual order.
- **Status tags** always carry their text, so colour is never the only signal.
- **Motion.**
  - Smooth scrolling for "See how it works" runs only under `prefers-reduced-motion: no-preference`.
  - After the jump, focus moves to the "How it works" heading (`tabindex="-1"`).
- **Zoom.** The page works at 200% text zoom and at 320px width with no horizontal scroll. Tap targets are at least 44 by 44px.

### Meta and sharing

- **Title:** `Tunehold: the music you own, on the web, iPhone and Android` (59 characters)
- **Meta description:** `Add a folder of your music and play it on the web, iPhone and Android, offline on your phone too. No server to set up. In development, by invite.`
- **Robots:** `noindex`, which I suggest while the page is only for the founder and friends. Nothing here needs search traffic. This is the founder's call.
- **Open Graph:**
  - `og:title` `Tunehold`, and `og:description` the same as the meta description.
  - `og:image` is 1200x630, following the logo brief: the lockup and one line on `#100E17`. The line is "The music you own, on the web, iPhone and Android." in `#F3F1F8`.
  - The image has no screenshots of other apps and no quotes.
- **Favicon:** from the logo brief's favicon set once it exists. Until then, use a plain "T" in `accent` on `#100E17`, or nothing.
- **No analytics, cookies or tracking scripts.**

### Call to action

**The hero button is "See how it works", and it scrolls to `#how-it-works`.** I didn't use "Ask for an invite" with a `mailto:` link, for four reasons:
- A public way to ask for an invite is a waitlist by another name, and the waitlist is deferred.
- At this stage invites go to people the founder already knows, directly, so they don't need a button.
- Collecting requests from strangers starts the privacy work that is deferred with the rest of the legal work.
- An email address on a public page draws spam.

"See how it works" serves what the page is for: showing the product.

**"Log in"** (the header link and the final button) opens the app's sign-in page. It is the only route in for invited accounts. Until the app has a sign-in page:
- the header shows only the wordmark;
- the final section keeps its heading and replaces the line and button with "Tunehold is in development, for its maker and a few friends."

Each section has one button: the hero's "See how it works" and the final "Log in".

### Status tags

- "Works today": `success` text with a tick. This is an allowed use, because it's short status text.
- "In progress": `text-muted`.
- Don't use `accent-2`, which is for the "new" badge.
- Set the tags at publish time from what works in the deployed app. A card moves to "Works today" only when the feature works for an invited user, not when the code is merged.
- When "Works today" cards appear, keep the features intro line as it is.

### Left off the page on purpose

- Testimonials, user counts, ratings, logos and reviewer quotes.
- Comparisons and any other service's name, including "alternative to".
- Prices, plan names and the word "free".
- A waitlist, an email form or a `mailto:` invite request.
- Store badges.
- Links to terms, privacy, retention or copyright reports.
- Any promise about how long files are kept, or what happens if Tunehold winds down.

### Wording choices

| left out | why | used instead |
|---|---|---|
| "Your music collection, kept and carried with you" (headline) | "Kept" is an unbounded keep-claim. "Carried with you" echoes the tone phrase "take it with you", and `brand.md` keeps tone phrases out of headlines. | "The music you own, on the web, iPhone and Android." |
| "Stored as you uploaded it" and "Offline on your phone" as card titles | Both are tone phrases from `brand.md`, which belong in body copy, never in headlines. "Playlists play what's in them" was also left out as a title, because it implies a comparison (F2). | Neutral titles ("The exact file you added", "Downloads for offline", "Playlists and queue"), with the phrases in the body. |
| "Used by its maker and a few friends" | Nothing is built yet, so nobody uses it. | "For its maker and a few friends." |
| "Zero setup" | It isn't literally true: there's an invite, an account and, on phones, a test build. | "No server to set up or keep running." |
| "Play it everywhere" | It isn't exact, because no TV, car or speaker apps are planned. | "On the web, iPhone and Android." |
| "No ads in your library, on any plan" | Plans are deferred, so "on any plan" has nothing to refer to. | "Your library has no ads." |
| "A lighter copy only for playing over slow connections" | F6 says the lighter copy is the streaming copy, not a slow-network fallback. | "A separate, lighter copy for streaming." |
| "Downloads stay until you remove them or delete the track" | The F5 model has more removal cases (signing out of the device, takedowns, account deletion), so the line would be incomplete. | "Downloaded tracks play straight from the phone, with or without a connection." |
| "If Tunehold ever winds down, everyone hears first, with time to export everything" | It's a retention and shutdown commitment, which is deferred with the legal work. Full-file export isn't built either. | Export staged honestly, plus the FAQ "Should I keep my original files? Yes." |
| "Export whenever you want" | "Whenever" is close to an absolute. | "Export on demand." |
| "Albums you bought as downloads" | `brand.md` keeps "download" for a copy on the phone. | "Albums you bought as files." |
| "Ask for an invite" (`mailto:`) | See Call to action. | "See how it works." |
| "Tunehold stores each file… and plays it…" (hero), "Yes" (offline FAQ), "the app shows" (space FAQ) | Present tense reads as a product that already works, and nothing is built yet. | "is being built to…", "It's being built to…", "will show", plus an intro line under "How it works". |
| "You usually need a computer at home" (problem) | Overstates it: some hosted services already need no server, and saying "usually" implies a claim about them. | "Playing your own files from a server at home means…" |
| "It doesn't replace your tracks with other recordings" | Only makes sense against services that do, so it reads as a comparison. "Bit for bit" already says it. | Dropped. |
| "Notifications stay off unless you turn them on" | Not exact: account messages, like a password reset, still arrive (F3: only non-transactional ones are off by default). | "Optional notifications stay off unless you turn them on." |
| "The apps aren't in the app stores" (FAQ) | Store content is deferred and stays off the page. | "Invited people get the iPhone and Android apps as test builds." |

### Checks run on this draft (2026-10-04)

These were run on a copy of this file in the session scratchpad, because the sweep skips `replica/`. They were re-run after the audit edits (the last five rows of Wording choices), with the same results:

- **`sweep.py <copy> --config replica/brand.json`:** clean, exit 0. No hits for the original's name, domains or colours.
- **`sweep.py <copy> --avoid` with the four `sweep_with_avoid` labels from `brand.json`, plus the `check_by_eye` tier and feature words:** clean, exit 0.
- **Case-sensitive search** for the original's library label (Title case) and for the split or mid-capital spellings of the name: nothing found.
- **"Hold"** appears only inside "Tunehold", so there are no hold puns.
- **Page copy (Header to Footer).** None of these appear:
  - absolute or catalogue words: "never", "unlimited", "forever", "ad-free", "random", "streaming service", "everywhere", "discover", "millions", "backup", "safe"
  - plan words: "quota", "upgrade", "free", plan or price words
  - other services' names, comparisons or "alternative"
  - store, legal and waitlist words: "app store", "terms", "privacy", "legal", "copyright", "waitlist" (the Footer line's build note "No legal links, store badges…" is not page copy)
  - present-tense claims that the app already works: unbuilt features are phrased as "being built to", sit under the Features heading, or follow the "In development" line
  - exclamation marks
- **Vocabulary.**
  - "Download" always means a copy on the phone, and "export" means getting everything out.
  - "Upload" appears only in body text, never on a button.
  - The buttons are "See how it works" and "Log in".
