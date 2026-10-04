# verify-fit: adversarial check of fixes.draft.md (fit, feasibility, already shipped)

2026-10-04 · checks every Fix (F1 to F8) and every Angle (A, B, C) in `analysis/fixes.draft.md` · default stance: distrust.

**Verdict: does not pass as written.** The fix list is mostly buildable and none of it promises a catalogue, but:

1. **Angle A's support is overstated.** "67 reviews across 3 sources" is really 59 HN comments plus 8 store rows. On my reading of all 12 store rows in the draft's own-files themes, 1 is about owned files.
2. **The B and C "proof points" come from catalogue listeners.** 0 of the 116 free-tier-control reviewers mention files they own, and 26 of the 27 offline complaints are about the original's catalogue downloads. Against the real alternatives for owners, those proof points are already offered.
3. **Four fixes compare against the original wrongly.** For F2, F7, F8 and the F5 own-files framing, the original already ships the feature or a close version that the draft missed (autoplay off-switch, data export with lifetime history, Recents and weekly stats).
4. **Sizes and claims need fixing.** F4 is M, not S. F7 has a storage cost with no upper limit. F5's "no expiry" contradicts paid offline. F6's desktop watch-folder is a fourth client.

Details, counts and the strongest counter-case follow.

## 1. Method and what I computed

- **Inputs, read-only:** `replica/reviews.csv` (1227 rows: app-store 1028, google-play 60, hacker-news 139) and the draft's theme URL lists in `analysis/synth/recount.json` (the object under audit). Also `spotify-changelog.verified.json` and `upload-market.verified.json`. Reddit, Trustpilot and the original's community board were unreachable and are not in the data.
- **New official fetches:** 4 pages fetched once on 2026-10-04 by `analysis/verify-fit-raw/fetch.py`, all HTTP 200: the original's support articles *Autoplay tracks* (updated 2025-09-25), *Understanding your data* (2026-07-07), *Data rights and privacy choices* (2025-09-18) and *Recent activity* (2025-06-30). Quotes from them are checked as exact substrings of the visible page text (`verify-fit-raw/texts.json`).
- **Scripts:**
  - `analysis/verify-fit.py` holds the keyword nets, my manual codes (keyed by URL, so anyone can dispute them) and all counts. It writes `verify-fit.json` with the URL lists.
  - `analysis/verify-fit.quotes_context.py` prints the full review behind each of the 24 quotes in sections 4–7 of the draft (all 24 exact; output in `verify-fit.quotes_context.json`).
  - `analysis/verify-fit.check_quotes.py` machine-checks every quote in this file.
- **Method:** keyword nets only generate candidates; I read every candidate in full and coded it by hand. One coder (me), no second rater.
- **Hand-read in full:** playlist injection (33), offline (27) and shuffle (25), plus the owner-signal hits (2 in free-tier control, 13 across all 1088 store reviews) and all 12 store rows in the own-files themes.
- **Sample caveat (applies to everything):** the HN comments came from ownership searches. They show reasons and wording, never prevalence.

## 2. Five findings that change the fit picture

| # | finding | n (method) | consequence |
|---|---|---|---|
| 1 | Free-tier control reviewers who own files | **0 of 116** (owner net: 2 hits, both use "my own song" for a chosen catalogue song) | B's volume comes from people who can't use tunebox. F1 is hygiene, not a pitch |
| 2 | Store rows in the draft's own-files themes that are about owned files | **1 of 12** (hand-coded). The other 11: 4 want YouTube/SoundCloud content, 3 want to move catalogue playlists elsewhere, 3 are ownership statements, 1 is ambiguous | A's demand is visible only on HN. By the thin rule (single source), **the upload demand itself is thin** |
| 3 | Store reviews that clearly ask to upload files the reviewer legally holds | **0 of 1088** (owner net: 13 hits, all read) | Mainstream "upload" requests are for content people don't own: a copyright red flag, not a market |
| 4 | Playlist-injection reviewers by tier | **16 free, 5 paying, 12 unknown** of 33. Of the 13 core reviews dated after 2026-05-13: **10 free, 3 unknown, 0 paying** | Complaints after the off-switch come from free users, for whom Smart Shuffle is always on by design. The draft's "13 of 25 after the article" doesn't show the fix failing |
| 5 | Offline complaints by what was played | **26 of 27 the original's catalogue downloads**, 1 Local Files | C answers a catalogue failure. Owners on the original's Local Files already play offline |

Who owners actually compare tunebox against: in the 76-row owner set (own-files themes plus self-host movers; HN 64, app-store 9, google-play 3), reviewers name **Apple Music 15, Plex/Plexamp 12, YouTube Music 11, Navidrome 8, Jellyfin 6, Bandcamp 6, Google Play Music 5, the Subsonic family 4, VOX 1 and iBroadcast 0** (keyword counts, rows checked). The mental competitor set is self-hosting plus the catalogue apps that accept uploads, not small lockers.

Segments inside the owner set (hand-coded, all HN unless stated, so all **thin**):
- **Gap-fillers want uploads alongside a catalogue,** which Apple Music and YouTube Music already provide and tunebox can't: 6 (HN 6). Two examples: “Apple Music (and GPM before it) lets me upload my own tracks and sync them between my devices.” ([hacker-news, 2024-04-08](https://news.ycombinator.com/item?id=39968033)) and “Plus with YT Music you can upload your own FLAC/MP3s to it” ([hacker-news, 2025-06-17](https://news.ycombinator.com/item?id=44295699)).
- **Subscription-averse:** 4 (HN 3, app-store 1). “Im not interested in being held hostage to pay a company xx$ a month for literally my entire life.” ([hacker-news, 2026-02-15](https://news.ycombinator.com/item?id=47021054)) · “At current Spotify prices, that is nearly $8000.” ([hacker-news, 2024-02-19](https://news.ycombinator.com/item?id=39430718))
- **Want to share their uploads with other people:** 0. The 2 share-keyword hits in the owner set are about a family *plan*, and a net over all 1227 rows found 0. This matters for the legal section (d).

## 3. Fix-by-fix verdict

Legend: **(a)** fit for a product with no catalogue · **(b)** already shipped (original / competitors) · **(c)** size and skill · **(d)** legal and brand.

### F1. Every control on every plan (draft: S, /replica-launch + /replica-build)
- **(a) Weak fit for the cited people.** 0 of 116 own files (finding 1). The draft's quote is a free catalogue listener rated 5★. The rule costs nothing and is right, but it is hygiene.
- **(b) Already offered elsewhere.** The original's Premium has every one of these controls, and it markets them: «Repeat songs, play albums in any order, and skip as many times as you want.» (https://www.spotify.com/us/premium/). Free has had Search & Play since 2025-09-15. No verified locker limits playback controls, so this is table stakes against the real competitors. It differentiates only against the original's free tier.
- **(c)** S is right. The skill is /replica-launch for the plan matrix, plus /replica-backend for the entitlement list (storage, offline, quality, seats). /replica-build has nothing to do, because the rows are already *must*.
- **(d)** Don't echo the original's Premium wording ("skip as many times as you want"). Aimed at the mass market, "unlimited skips on every plan" reads as free on-demand music, which is an **implied catalogue promise**.
- **Pricing conflict the draft misses:** F1 makes plans differ by "offline downloads". YouTube Music plays uploads offline without Premium, per a user quoting Google's help page: «You can play uploaded songs in the background, ad-free and offline—even if you are not currently a YouTube Music Premium subscriber.» (user-quoting-official, https://news.ycombinator.com/item?id=46520232). Resolve this in /replica-launch.
- **Verdict:** keep as policy. Drop it as a marketing proof point.

### F2. Playlists play only what's in them (draft: S, /replica-build)
- **(a)** The complaint is real, but it comes from the wrong segment (finding 4). Two of the 5 paying complainers predate the off-switch by years (2023-07, 2023-10), two are from 2025 (2025-06 and 2025-08), and the one from 2026-08 is about autoplay. The draft's quote comes from a free-tier reviewer ("i can skip songs 6 times").
- **(b) Already shipped by the original** (the draft missed this):
  - Premium can turn Smart Shuffle off: «Switch Include Smart Shuffle in play modes off .» (https://support.spotify.com/us/article/shuffle-play/, 2026-05-13).
  - Autoplay has an on/off switch on mobile and desktop, and the article shows no Premium label: «Under Playback, scroll down to Autoplay and switch it on , or off .» (https://support.spotify.com/us/article/autoplay/, updated 2025-09-25).
  - The newsroom announced both: «Prefer to stick with your own picks during your listening sessions? You can easily switch Autoplay and Smart Shuffle off in your settings for full control.» (https://newsroom.spotify.com/2025-05-07/experience-a-new-dimension-of-music-discovery-with-more-controls-and-enhanced-tools/).
  - A reviewer confirms it: “So they finally gave the option to disable smart shuffle, I can rate Spotify more than 1 star now.” ([google-play, 4★, 2026-04-13](https://play.google.com/store/apps/details?id=com.spotify.music&hl=en_US&gl=US#review-2))
  - **The only difference left is the default (off).** Lockers have no catalogue to mix songs in from, so this is table stakes there too.
- **(c)** S, provided the opt-in "similar songs from my library" uses tags (same artist or genre). Anything smarter is M.
- **(d)** "Never slips in a song you didn't add" is an implied comparison. Keep it out of ads.
- **features.csv correction:** the proposed row `Playlists play only their own tracks; autoplay off by default` should be **original = yes** (both can be switched off), with the note "difference = default off".
- **Verdict:** keep as hygiene (S). It is not a differentiator.

### F3. A quiet, music-only app (draft: S, /replica-design + /replica-build)
- **(a) Good fit.** "Paying and still getting ads" (33, 3 sources) is the one ads theme whose reviewers pay. Clutter (49) and UI churn (40) are HN-heavy (24 and 17). One owner in the data took exactly this path: a Premium subscriber hit with promo pop-ups who moved to Plex and ripped CDs: “via full-screen modal popups in the app with no way to prevent them” ([hacker-news, 2023-04-06](https://news.ycombinator.com/item?id=35462336)). Rating prompts are **thin** (12, app-store only).
- **(b)** A differentiator against the original, table stakes against lockers. iBroadcast: «There are no fees to use iBroadcast and no ads.» (official listing, https://apps.apple.com/us/app/ibroadcast/id536363915). Substreamer: «free, with no ads, no subscriptions, and no data collection.» (official listing, https://apps.apple.com/us/app/substreamer/id1012991665).
- **(c)** S is right (mostly policy). "Never forced mid-session" needs a client-version policy for web deploys, which is still S.
- **(d)** Never say "ad-free music" to a mass audience, because it implies ad-free commercial tracks. Say "no ads in your library, on any plan".
- **Verdict:** keep. Its value is retention (don't become what owners left), not acquisition.

### F4. A shuffle you can check (draft: S plus a small backend piece)
- **(a) Fair fit.** 25 reviews (app-store 19, hacker-news 5, google-play 1), mostly large collections of 300–3000 songs, which is the closest catalogue theme to collector behaviour. There is one owner-side buying signal (**thin**, 1 HN): “If this player has true random playing of your songs, instant sell for me.” ([hacker-news, 2026-09-01](https://news.ycombinator.com/item?id=49523937))
- **(b)** The original already has a "Fewer Repeats" default (2025-11-13), a Standard style for Premium, a reshuffle button (2026-05-28) and tap-to-play-next while shuffling. The draft rightly narrows the difference to "once per cycle, kept across devices". But `upload-market.verified.json` has **nothing on how the lockers shuffle**, so no claim against lockers is supported. Treat it as parity until someone checks.
- **(c) Size it M, not S.** A permutation on one device is S. Keeping the cycle across devices, surviving adds and deletes mid-cycle, working with the user queue, and shuffling a whole library of tens of thousands of IDs is M. `PlaybackState` is marked "confidence: guess" in recon, so **/replica-architect** has to specify it before /replica-build and /replica-backend.
- **(d) / counter-risk** (background, not verified here): a truly random order still produces runs of one artist that people also hear as "not random". Offer a "spread artists" option and never market "truly random".
- **Verdict:** keep, resize to M, and drop the comparison with lockers.

### F5. Offline-first downloads (draft: L, /replica-build + /replica-backend + /replica-architect)
- **(a) Weak as a pitch** (finding 5). The complainers paid for downloads (the original's support page: «On the free version, you can only download podcasts.»), so they are a good buyer profile, but what they want offline is the catalogue. For owners, the original's Local Files plays «audio files legally stored on your device» (https://support.spotify.com/us/article/local-files/), which already works offline. **The draft's `original = no` comparison for owned files is apples to oranges.**
- **(b) Parity with the owners' alternatives:**
  - YouTube Music plays uploads offline without Premium (user-quoting-official, cited under F1).
  - Plexamp: «Grab a few hours of your favorite playlist or stations with just a few taps.» (official listing, https://apps.apple.com/us/app/plexamp/id1500797510).
  - Minor: the original's two support articles disagree on its download cap ("on each of up to 5 devices" vs "across up to 5 devices", changelog findings 26 and 27). The draft quotes only one.
- **(c)** L is right. Add **/replica-launch**: if offline is the paid hook, the in-app purchase rules on iOS and Android apply, and the paywall sits where YouTube Music is free.
- **(d) Contradiction:** "no expiry for own uploads" sits next to "offline is a paid feature, re-check the plan". Pick one:
  - **(i)** downloads are plain copies of the user's own files that never expire (honest; then the paid part is sync convenience, not access), or
  - **(ii)** downloads expire after a lapse plus a grace period (then drop "no expiry").

  "Never silently purge" also depends on the storage location: the OS can clear cache folders (background knowledge, check current iOS and Android docs).

  "Offline-first cuts egress" is only partly true. Downloading a whole library to several devices front-loads egress, so set a device limit.
- **Verdict:** keep as a *must* for mobile owners, demote as a differentiator and angle, and fix the wording of the new feature row.

### F6. The locker done right (draft: L, /replica-backend + /replica-build)
- **(a)** This is the core product. Evidence: upload my own files 34, but 28 are HN, and of the 6 store rows 1 is about owned files while 4 want YouTube/SoundCloud content (finding 2).
- **(b) Table stakes, not a differentiator:**
  - YouTube Music: «Upload songs from your devices so you can enjoy them in one place with YouTube Music» (official listing, https://apps.apple.com/us/app/youtube-music/id1017492454), «It supports up to 100k uploads» (user-quoting-official, https://news.ycombinator.com/item?id=46518743).
  - VOX: «FLAC remains FLAC» and «Unlimited music cloud storage for your music collections;» (official listing, https://apps.apple.com/us/app/vox-mp3-flac-music-player/id916215494).
  - iBroadcast: free uploads.
  - F6 differentiates only against Navidrome (no upload, by design) and the original (no cloud). "Never match or replace" differentiates against Apple, based on one 2024 HN comment (**thin**). The market file *dropped* the claim that YouTube Music matches uploads to other audio (a reply says it can be turned off).
- **Overgeneralisation:** "Plexamp users complain of no M3U import" rests on **one** App Store review. Write "a Plexamp reviewer" (**thin**).
- **(c)** L is right, but the "desktop watch-folder" is a **fourth client** (a desktop app) outside the web + iOS + Android scope. That is a separate L, out of v1. Keeping the original file plus a streaming copy adds storage, so /replica-architect should own the cost model.
- **(d)** Whole-folder upload invites unlicensed collections. The defensible frame is a *private* locker: terms where users certify their rights, and no public access by default (see the legal section).
- **Verdict:** keep as *must*, labelled table stakes.

### F7. Your library leaves with you (draft: M, /replica-backend + /replica-launch)
- **(a) The cited reviews don't fit.**
  - Quote 1 is from someone who cancelled Premium and found their *downloaded catalogue* greyed out: “when i cancelled my premium subscription and when it actually came off, i cant listen to a SINGLE song” ([app-store, 1★, 2026-10-02](https://itunes.apple.com/us/rss/customerreviews/page=6/id=324684580/sortby=mostrecent/xml#review-14618139577)). The same review continues with "bc I think I have it downloaded “offline”". That is a catalogue and offline bug, not owned files.
  - The export_transfer store rows (3) want to move *catalogue* playlists to another streaming service.
  - For owners, the trust need rests on market facts (Google Play Music deleted uploads in 2021; Amazon ended storage in 2017) and on 4 subscription-averse owners (**thin**). That works as trust insurance, not as an answer to the quoted reviews.
- **(b) Already shipped by the original** (the draft missed this). "The verified changelog shows no export" is true of that file but false of the product:
  - «You can get a ZIP file with a copy of your personal data by using the automated Download your data tool on your Account Privacy page or by contacting us.» (https://support.spotify.com/us/article/data-rights-and-privacy-settings/).
  - The export covers playlists, even «Local track name, if the user uploaded locally saved audio to be played on Spotify service.», and lifetime history: «A list of items (e.g. songs, videos, and podcasts) listened to or watched during the lifetime of your account» (https://support.spotify.com/us/article/understanding-your-data/, updated 2026-07-07).
  - **What's left for tunebox:** export on demand, in standard formats (M3U8/CSV), with the audio. But owners already hold the originals they uploaded, so exporting files is a backup, not relief from lock-in. The row `Playback and export stay on after downgrade or cancel` with original = no doesn't compare like with like: when Premium ends, the original still plays the library on its free tier (free Search & Play since 2025-09-15). Drop that comparison.
- **(c)**
  - Playlists and history export: M.
  - Exporting the original files of a collector library (96–300 GB per 10,000 tracks, by the draft's own arithmetic) is not a one-click zip. It needs a manifest of signed URLs and a resumable download, so M–L, plus egress.
  - **"Playback and download continue after cancel" means storing data for people who no longer pay, with no upper limit.** Make it time-boxed: read-only plus export for N days, then deletion with notice. Decide in /replica-launch, then legal.
- **(d)** "Never held hostage" and "your files never disappear" are absolute claims a startup can't back (lockers have shut down before). Promise instead: "always exportable, with N days' notice before any deletion or shutdown", plus the DMCA caveat.
- **Verdict:** keep, rescope, and fix the comparison with the original.

### F8. Collector tools (draft: M, /replica-build + /replica-backend)
- **(a) Fair fit.** Library tools 18 (10 of them from 4–5★ reviews), history 9 (HN 5). Small, but from more than one source. An HN owner asks for tags and stats ([40472070](https://news.ycombinator.com/item?id=40472070)).
- **(b) The original already ships part of it** (the draft missed this):
  - Recents: «To view the last 50 songs you listened to: Click the Play Queue at the bottom. Click Recents.» (https://support.spotify.com/us/article/recent-activity/).
  - Weekly stats: «The new weekly listening snapshot shows you your top songs and artists every week, perfect for tracking trends between Wrapped.» (https://newsroom.spotify.com/2025-12-29/year-in-features/).
  - Static rule-like playlists: «In select markets, you can generate new playlists from your Liked Songs by filtering them by genre or mood.» (https://newsroom.spotify.com/2025-09-05/new-user-controls-personalize-listening/).
  - Lifetime history export (F7).
  - Navidrome has «Multi-user, each user has their own play counts, playlists, favorites, etc..» (official docs).
  - **What's left:** in-app play counts per track (none found in the pages checked) and live-updating rule-based playlists. For history, mark original = partial.
- **(c)** M is right.
- **(d)** Privacy: PlayEvent export and deletion. The draft already covers it.
- **Verdict:** keep, and correct the "original" column for history.

### Summary table

| fix | (a) fit, no catalogue | (b) shipped by the original | (b) offered by competitors | (c) draft → checked size | verdict |
|---|---|---|---|---|---|
| F1 | rule fits; cited people don't (0/116 own files) | yes, on Premium | table stakes | S → S | keep as policy, not a proof point |
| F2 | real, but post-switch complaints are free users | **yes** (Smart Shuffle off, Autoplay off) | table stakes (no catalogue) | S → S/M | hygiene; fix original = yes |
| F3 | good (payers, HN owners) | no (differentiator) | table stakes (iBroadcast, Substreamer) | S → S | keep (retention) |
| F4 | fair (large collections) | partly (Fewer Repeats, reshuffle) | unverified | **S → M** | keep, resize, no locker claim |
| F5 | weak as a pitch (26/27 catalogue) | own files: Local Files already offline | YouTube Music uploads offline for free; Plexamp | L → L | must-have; fix "no expiry" |
| F6 | core product | n/a (no cloud) | **table stakes** (YouTube Music, VOX, iBroadcast) | L → L (+ watch-folder is a separate L) | must, not a differentiator |
| F7 | trust insurance; cited quotes misfit | **partly** (JSON data export with lifetime history) | Google Play Music had Takeout | M → M–L | rescope; time-box post-cancel |
| F8 | fair | **partly** (Recents, weekly stats, filters) | Navidrome play counts | M → M | keep; original = partial |

## 4. Angles

**A. "Own it, play it everywhere"**
- **(a)** Passes if "untouched" is defined as the *stored* copy (free-plan streams are transcoded under F6, so "plays untouched" would be false) and if offline paywalling is resolved (F5).
- **(b)** Its core promise (your files in the cloud, everywhere) is what YouTube Music uploads (free), iBroadcast (free), VOX ($4.99/month, unlimited, FLAC stays FLAC) and Apple's cloud library already sell. **A gets tunebox into the category. It does not differentiate it.**
- **(d)** "One-click way to take everything back out" must hold at 300 GB. "Changes under them" needs the DMCA caveat.
- **(e)** The evidence is overstated (findings 2 and 3). Six HN owners want uploads *alongside* a catalogue, which tunebox can't offer.

**B. "Your music, your rules"**
- **Fails (a).** It is addressed to "listeners who want a player that does exactly what they tell it", and to the original's free users that reads as on-demand music for free: an implied catalogue promise. 0 of 116 own files.
- **(b)** Parity with Premium, table stakes against lockers.
- **(d)** The slogan is generic. Run the trademark check in /replica-brand. Comparative use carries the copycat risk the draft already notes.
- **Verdict:** keep it as voice, never as headline or proof point.

**C. "Offline that never lets you down"**
- **Fails fit.** 26 of 27 complaints are catalogue downloads. For owners, Local Files already plays offline, YouTube Music uploads play offline for free, and Plexamp has downloads. It is L-sized.
- **(d)** "Never lets you down" is an absolute reliability claim.
- **Verdict:** use F5 as a feature line under A, not as an angle.

**"All three lenses reached A independently"** is true (fit.md, market.md and evidence.md each recommend A), but all three coded the same HN-heavy sample. Agreement between them is not independent market evidence.

### The strongest counter-case (e)

1. **The B and C proof points don't hold.** The draft says F1–F4 are "cheap proof that tunebox is a better place for owned files than other lockers". Nothing in either verified file shows a locker that mixes in songs, caps skips or gates controls. Findings 1, 4 and 5 show the evidence for B and C comes from catalogue listeners. **Where owners decide, against YouTube Music uploads, iBroadcast, VOX and Plex/Navidrome, those proof points are parity.**
2. **A better-supported version of A:** "a hosted home for a collection, with no server". Aim it at people who self-host or are considering it (owners name Plex 12, Navidrome 8, Jellyfin 6, Subsonic 4) and at Google Play Music refugees whose YouTube Music uploads are degrading. Use proof points measured against *those* options:
   - zero setup: “if something takes more than a few clicks to go from zero to music that leaves 95% of users out!” ([hacker-news, 2026-09-01](https://news.ycombinator.com/item?id=49518972));
   - whole-folder upload with originals kept (F6);
   - always exportable, time-boxed (F7);
   - a shuffle and history built for large collections (F4, F8).

   F1–F3 then become hygiene. Same evidence as A, but each proof point has at least one owner-side review behind it.
3. **A feasibility hedge the draft rejected inconsistently.** It dropped a Subsonic-compatible API as "HN-only, thin". By that same rule, A's upload demand is also HN-only, since 59 of its 67 reviews are HN. A Subsonic-compatible API (about M) would let existing clients play tunebox libraries, with offline, before the L-sized native offline work (F5) ships. Substreamer is free, Symfonium is paid, Amperfy exists (official listings in the market file). The trade-off is less control of the brand and the UX. It belongs in /replica-architect as an option, not a v1 promise.
4. **The case against A itself.** In 1088 recent store reviews nobody clearly asks to upload files they own. The visible owners are HN users, many already served by self-hosting or by Apple Music / YouTube Music uploads, and 4 are subscription-averse. Free competitors cap the price near zero. **The draft's landing-page and waitlist test should be a hard gate before any L-sized work on storage, transcoding or offline, not a suggestion.**

**Net recommendation:** keep A as the category, because it is the only angle where buyer and product match. Restate its evidence honestly: HN-sourced, thin in store reviews, size unknown. Replace the B and C proof points with the locker-relative ones in point 2, and make the test a gate.

## 5. Legal and brand risk beyond the draft (not legal advice)

- **Public sharing of uploaded audio is the biggest exposure, and the evidence shows no demand for it** (0 requests; finding in section 2). features.csv still has `Share a playlist by link` (should), `Public profile with public playlists` and `Collaborative playlist` ("only among users who each own the tracks they add" can't be enforced).
  - *Background, not verified in this session:* EU Directive 2019/790 (Art. 2(6)) excludes cloud services where users upload content only for their own use from the platform rules in Art. 17. Public sharing could bring tunebox into scope, with licensing and filtering duties.
  - *Also background:* US safe harbour (17 U.S.C. §512(c)) depends on conditions such as no direct financial benefit from infringement that the service can control. Music lockers that streamed uploads to others have been sued (MP3tunes, Grooveshark).
  - **Recommendation:** in v1, a share sends the *tracklist only*, and a recipient can play only tracks they uploaded themselves. Revisit with counsel.
- **Store "upload" requests are for YouTube/SoundCloud content** (4 of the 6 store upload rows). Don't word any copy so that it answers them. The draft already warns about this; keep that warning.
- **Absolute claims:** "never disappear", "never held hostage", "never lets you down", "no expiry" (F5/F7/C). Replace them with bounded, policy-backed wording.
- **"Untouched"** must mean the stored file (F6 transcodes streams on lower plans).
- **Comparative copy:** F1/F2/B are implicit comparisons with the original's free tier. Keep them out of ads and listings. *Background:* the App Store rules restrict other apps' names and trademarks in metadata; check the current wording in /replica-launch.
- **Testimonials:** the draft forbids them correctly. Nothing in sections 4–7 uses a review as copy.
- **Name:** "tunebox" needs the trademark, store and domain checks in /replica-brand. Nothing was checked here.

## 6. Context problems in quotes the draft cites (all 24 are exact substrings; the issue is fit)

| where | quote's real context | fix |
|---|---|---|
| F7 | cancelled Premium, downloaded catalogue greyed out ("bc I think I have it downloaded") | drop it as evidence of owner lock-in, or label it a catalogue bug |
| F2, F1 | both reviewers are free-tier catalogue listeners | fine as illustrations, but say whose problem it is |
| U2 | “As infuriating as this is, it's the reason I still use Spotify.” ([hacker-news, 2024-04-08](https://news.ycombinator.com/item?id=39967357)): the commenter *likes* that removed songs stay visible | use it only for "tell me what changed", not for "library doesn't change" |
| U3 | “Perhaps things have changed, but 10 or so years ago” ([hacker-news, 2024-11-12](https://news.ycombinator.com/item?id=42113467)): describes the original's behaviour around 2014 | mark it as historical, not current |
| F6 | the quoted HN comment says Apple Music and YouTube Music already allow uploads | read it as parity evidence, which is what it is |

## 7. Edits required in fixes.draft.md

1. Section 6 A evidence: replace "67 reviews across 3 sources" with "67 core reviews, 59 of them HN. Of the 12 store rows in the own-files themes, 1 is about owned files. **Thin outside HN.**"
2. Recommendation: replace "use B and C as the proof points" with locker-relative proof points (section 4, counter-case point 2). Move F1–F3 to hygiene.
3. F2: the original ships Smart Shuffle off and Autoplay off. Set the features.csv row to original = yes, with "difference = default". Reword "13 of 25 core after the article" to "10 of those 13 are free-tier users".
4. F4: size M. /replica-architect specifies PlaybackState first. Delete the claims against lockers.
5. F5: resolve "no expiry" against the paid gate. Compare owned files with Local Files and YouTube Music uploads, not with catalogue downloads. Cite both download-cap wordings.
6. F6: label it table stakes. Change "Plexamp users" to "a Plexamp reviewer (thin)". Move the desktop watch-folder out of v1.
7. F7: replace "the verified changelog shows no export" with the original's Download your data tool (playlists plus lifetime history as JSON). Time-box post-cancel playback and export. Drop the misfit quote. Remove "original = no" from the post-cancel row.
8. F8: history is partial on the original (Recents, weekly snapshot, export).
9. Section 7 pricing: flag the conflict between paid offline and YouTube Music's free offline uploads, and the 4 subscription-averse owners (thin).
10. Legal: add "share = tracklist only in v1", for the reasons in section 5.
