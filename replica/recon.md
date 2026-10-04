# Recon map: Spotify (web + iOS + Android)

Scope: the personal-library music player loop. Upload your own audio, organize it into a library and playlists, and play it everywhere with a queue, offline downloads and sharing. The Spotify catalogue, recommendations and social graph are out of scope (see below).
For: a product to sell. Codename **tunebox** (never "Spotify" in code, assets or copy).
Date: 2026-10-04

## Method and terms

- The Spotify Terms of Use and User Guidelines forbid reverse-engineering, decompiling or making derivative works of the Spotify software and service. So this recon uses **public sources only**: help articles, reporting, the newsroom, store listings and pricing. It does not drive the user's account, read app bundles or log network calls.
- spotify.com, support.spotify.com and developer.spotify.com are blocked from the build container. The facts below come from public third-party coverage and Spotify's newsroom, plus well-documented, long-standing product behaviour. Everything that needs checking against the real app is marked `confidence: medium` or `guess`.
- `replica/screens/` is empty for now. Reference screenshots of public store listings can be added later for `/replica-diff`. They never ship.

## Sources

| # | source | URL | notes |
| --- | --- | --- | --- |
| 1 | pricing coverage (2026) | https://www.nerdwallet.com/finance/learn/how-much-does-spotify-cost | Individual $12.99, Duo $18.99, Family $21.99 (6 accounts), Student $6.99 |
| 2 | plan breakdown | https://freeyourmusic.com/blog/how-much-is-spotify-premium | Premium gates: no ads, on-demand, offline downloads, lossless, audiobook hours |
| 3 | terms (reverse-engineering clause) | https://www.spotify.com/us/legal/user-guidelines/plain/ | Basis for "public sources only" |
| 4 | Local Files how-to | https://www.soundguys.com/how-to-upload-local-music-files-to-spotify-102609/ | Closest original feature to tunebox's core: device files only, mp3/m4p/mp4, no cloud upload |
| 5 | Local Files how-to | https://www.androidauthority.com/how-to-upload-music-to-spotify-3079613/ | Settings path, "Local Files" folder in Your Library |
| 6 | newsroom: folders + queue | https://newsroom.spotify.com/2026-05-28/playlist-folders-mobile-queue-controls-updates/ | Playlist folders on mobile, upgraded queue controls |
| 7 | newsroom: tablet app | https://newsroom.spotify.com/2026-04-16/new-tablet-app-experience/ | Dedicated tablet layout |
| 8 | newsroom: taste profile | https://newsroom.spotify.com/2026-03-13/taste-profile-beta-announcement/ | Personalization (out of scope) |
| 9 | newsroom: video controls | https://newsroom.spotify.com/2026-04-09/video-control-settings-update/ | Video (out of scope) |
| 10 | newsroom: Studio / Labs | https://newsroom.spotify.com/2026-05-21/studio-by-spotify-labs-launch/ | Remix/cover tools on licensed catalogue (out of scope) |

To add when the network allows: support.spotify.com (Your Library, Queue, Downloads, Playlists articles), App Store / Play listings, and public walkthrough videos.

## Core loop

**Put a song in, find it fast, press play, keep listening.** For tunebox, "put in" means upload. Spotify's paying users pay for on-demand, ad-free, offline listening. tunebox gives every plan the playback controls and downloads for the user's own files, and sells storage instead (see `fixes.md` F1, F5 and F7).

## Screens

| ID | screen | route / how to reach | purpose | key components | states seen |
| --- | --- | --- | --- | --- | --- |
| S01 | Landing / welcome | `/` logged out | Pitch + sign up / log in | Hero, CTA buttons | default, mobile |
| S02 | Sign up | `/signup` | Create account | Text inputs, social buttons, stepper | empty, validation error, loading |
| S03 | Log in | `/login` | Authenticate | Inputs, social buttons, "forgot password" link | error (wrong password), loading |
| S04 | Reset password | `/reset` | Recover access | Input, confirmation message | sent, expired link |
| S05 | Home | `/home` | Jump back in | Greeting, quick-pick grid (6–8 tiles), horizontal shelves of cards, filter chips | empty (new user → upload CTA), loading skeleton, filled |
| S06 | Search | `/search` (mobile tab, web top bar) | Find anything in the library | Search input, recent searches list, browse tiles by genre, results grouped by type with "top result" | idle, typing, results, no results |
| S07 | Your Library | `/library` (web left sidebar, mobile tab) | Everything you saved | Filter chips (Playlists, Albums, Artists, Downloaded), sort menu, list/grid toggle, pinned items, search-in-library | empty, filled, filtered empty, loading |
| S08 | Liked Songs | `/collection/tracks` | All hearted tracks | Collection header (gradient), play/shuffle buttons, track table | empty, filled |
| S09 | Playlist | `/playlist/:id` | View/play/edit a playlist | Header (cover, title, owner, count, duration), action row (play, shuffle, download, share, more), track table with drag reorder, "find more songs" search | empty playlist, filled, not owner (read-only), private/denied |
| S10 | Album | `/album/:id` | Tracks of one album | Header with cover/year, track list with numbers, discs | filled |
| S11 | Artist | `/artist/:id` | Artist's tracks/albums | Header, "popular" (most played), albums grid | filled, single-track artist |
| S12 | Now playing bar | persistent, bottom (web), above tab bar (mobile) | Control playback anywhere | Mini cover, title/artist, heart, play/pause, progress, (web) volume, queue, device, full-screen buttons | idle (nothing), playing, paused, buffering, error |
| S13 | Now playing full screen | tap bar (mobile) / expand (web) | Focused playback | Big cover, seek bar, transport, shuffle/repeat, lyrics card, share, queue, sleep timer (in "…") | playing, paused, with lyrics, no lyrics |
| S14 | Queue | queue button | See/edit what plays next | "Now playing", "Next in queue" (user added), "Next from: <context>", drag handles, remove, clear | empty queue, filled |
| S15 | Lyrics | from S13 | Synced lyrics | Scrolling highlighted lines | synced, unsynced, none |
| S16 | Track context menu / sheet | "…" on any row | Actions on a track | Menu: add to playlist (with search + "new playlist"), add to queue, go to album/artist, like, share, download, remove | default |
| S17 | Create / edit playlist dialog | "+" in library / "Edit details" | Name, description, cover | Modal, image picker, inputs | empty, saving, error |
| S18 | Upload (tunebox) | `/upload`, drag-drop anywhere on web, "+" on mobile | Add audio files | Drop zone, file list with per-file progress, tag preview, quota meter | idle, uploading, partial failure, quota exceeded (upgrade prompt follows the store billing route, `fixes.md` section 7), unsupported file |
| S19 | Edit track metadata (tunebox) | context menu → Edit | Fix tags/cover | Form, cover picker | default, saving |
| S20 | Profile | `/user/:id` | Public face (public profile and public playlists deferred past v1; shared playlists are text-only tracklists, `fixes.md` section 7) | Avatar, name, public playlists, followers/following | own, other user, private |
| S21 | Settings | `/settings` | Preferences | Toggles and selects: audio quality, crossfade, gapless, normalize, offline storage, language, notifications | default |
| S22 | Account / plan | `/account` | Plan, billing, quota, delete account | Plan card, compare plans, manage billing, storage meter | free, paid, payment failed, cancelled |
| S23 | Plans / checkout | `/premium` → checkout | Upgrade | Plan cards, checkout: hosted Stripe on the web; in the apps, store in-app purchase or no purchase UI, per the billing route in `fixes.md` section 7 | default, success, failure |
| S24 | Downloads (mobile) | Library filter "Downloaded" | Offline content | Download status per item, storage used | offline mode banner, downloading, done |
| S25 | Shared tracklist (link) | `/s/:token` | Recipient view of a shared playlist's tracklist, text only (titles, artists, albums, durations; no owner cover art, custom cover or lyrics). The recipient plays only matching tracks from their own library, never the owner's audio | Header (name, owner, count), text track list with matched and greyed-out rows, "open in app" / sign up CTA | shared, revoked, taken down, no matching tracks |
| S26 | Report content (tunebox) | context menu / shared page | Copyright report, plus other illegal-content reports where the launch country requires it (`fixes.md` section 7) | Form (report type, claimant, work, URL, statement) | sent |
| S27 | Keyboard shortcuts | `?` / menu (web) | Help | Modal list | default |

## Flows

```
F01 New user uploads first songs and plays one
    S01 -> S02 -> S05 (empty: "Upload your music") -> S18 (drop 12 files) -> S07 (album appears) -> S10 -> play -> S12
    happy path clicks: ~6 after sign-up (target to beat; Spotify Local Files needs a settings toggle + folder pick on each device)
    edge: unsupported format, file with no tags, duplicate file, quota exceeded mid-batch, connection lost during upload, very large FLAC

F02 Play music and keep it going while browsing
    S05 -> tile -> S09 -> play -> navigate to S06 -> music continues in S12
    happy path clicks: 2
    edge: track fails to load (skip to next), end of context with repeat off, shuffle on, network drop (buffer then error)

F03 Build a playlist
    S07 "+" -> S17 (name) -> S09 empty -> "find songs" search -> add x5 -> drag to reorder
    alt: S16 "Add to playlist" from any track row
    happy path clicks: ~4 + 1 per song
    edge: duplicate track warning, playlist with 0 tracks, very long playlist (virtualized list)

F04 Manage the queue
    S16 "Add to queue" / "Play next" -> S14 -> reorder / remove / clear
    happy path clicks: 2
    edge: queue + shuffle interaction, user queue plays before context, clear queue

F05 Like a song and find it later
    heart on S12 or row -> S08
    happy path clicks: 1
    edge: unlike from S08 removes row (undo toast)

F06 Search my library
    S06 -> type -> top result + grouped results -> play
    happy path clicks: 2
    edge: no results, accents/case, partial words

F07 Download for offline (mobile, every plan; the plan sets how many devices hold downloads)
    S09 -> download toggle -> S24 shows progress -> airplane mode -> play
    edge: device cap reached (plan prompt follows the store billing route, fixes.md section 7), low storage, download interrupted, file deleted on server or taken down (copy removed at next connection)

F08 Share a playlist (tracklist only)
    S09 "Share" -> copy link -> recipient opens S25 (text-only tracklist) -> plays the matching tracks they uploaded to their own library (never the owner's audio) or signs up
    edge: owner revokes link, track taken down by report, recipient has no matching tracks (rows greyed out), recipient on free plan

F09 Upgrade plan
    quota meter / device-cap prompt -> S23 -> checkout per the store billing route (web: Stripe; apps: store in-app purchase, or no purchase UI; fixes.md section 7) -> back to S22 paid
    edge: card declined, cancel (store-billed plans cancel in the store), downgrade or cancel with storage over the free quota (F7 over-quota rule: uploads paused; playback, downloads and export for N days; the user picks what to keep; the rest deleted after notice)

F10 Recover password
    S03 -> S04 -> email -> new password -> S05
    edge: expired link, unknown email (same response, no account leak)

F11 Report copyrighted content (tunebox)
    S25 or S16 -> S26 -> admin review -> takedown disables access (Track.status = taken_down; stored copy kept for a counter-notice; device copies removed at next connection; shared rows greyed out)
    edge: counter-notice (access restored), repeat infringer policy (termination under the terms), non-copyright report where the launch country requires it

F12 Settings & quality
    S21 -> audio quality / crossfade / gapless / sleep timer from S13
```

## Components

| component | variants | states | used on |
| --- | --- | --- | --- |
| Button | primary (pill, accent), secondary (outline), ghost/icon, circular play | default, hover, active, focus, disabled, loading | all |
| Big play button | play / pause, with shuffle toggle beside it | playing, paused | S08–S11 |
| Track row | numbered, with cover, playing (animated equalizer + accent title), unavailable/greyed, downloaded dot | default, hover (shows play icon in number slot), selected, playing, drag | S08–S11, S06, S14 |
| Media card | square cover, round (artist), with play-on-hover | default, hover, playing | S05, S06, S11 |
| Quick-pick tile | horizontal cover + title | default, hover, playing | S05 |
| Collection header | playlist, album, artist, liked (gradient from cover color) | default, editable (owner) | S08–S11 |
| Now playing bar | desktop full, mobile mini (with progress line) | idle, playing, paused, buffering | S12 |
| Seek / volume slider | seek, volume | default, hover (thumb shows), dragging | S12, S13 |
| Transport controls | shuffle, prev, play/pause, next, repeat (off/all/one) | active (accent + dot), inactive | S12, S13 |
| Sidebar (web) | expanded, collapsed | filter chips, pinned | S07 web |
| Bottom tab bar (mobile) | Home, Search, Library, (+ Upload) | active | mobile all |
| Filter chips | single-select, removable | default, selected | S05, S07, S06 |
| Context menu / bottom sheet | menu (web), sheet (mobile), nested submenu (add to playlist) | open | S16 |
| Modal / dialog | form, confirm (destructive) | open, saving, error | S17, S19, S26 |
| Toast | info, success, undo | shown, dismissed | global |
| Search input | header (web), page (mobile) | empty, typing, clear | S06, S07, S09 |
| Text input / select / toggle | — | default, focus, error, disabled | S02–S04, S21, S22 |
| Skeleton loaders | row, card, header | loading | all lists |
| Empty state | with illustration slot + CTA | — | S05, S07, S08, S09, S14 |
| Upload drop zone + file progress row | idle, drag-over, uploading, failed, done | — | S18 |
| Quota meter | bar + label | ok, near limit, full | S18, S22 |
| Plan card | free, paid tiers, current | default, selected | S22, S23 |
| Avatar | user, small/large | with image, initials | S20, header |
| Download indicator | none, queued, downloading (ring), done | — | rows, S09, S24 |

## Inferred data model

```
User        id, email, display_name, avatar_url, plan (free|premium|family...), created_at
            evidence: S02, S20, S22; pricing pages (sources 1–2)        confidence: high

Track       id, owner_id (User), file_key, mime, bitrate, duration_ms, size_bytes,
            title, artist_name, album_title, album_artist, track_no, disc_no, year, genre,
            cover_key, lyrics_lrc (nullable), checksum (duplicate detection within one user's library; no deduplication across users),
            status (processing|ready|failed|taken_down),
            play_count, last_played_at, created_at
            evidence: Local Files reads ID3 tags (sources 4–5); S09–S11 track columns   confidence: high (tunebox-specific fields: design decision)

Album       id, owner_id, title, album_artist, year, cover_key      (derived from Track tags, grouped per owner)
Artist      id, owner_id, name, image_key                            (derived from Track tags)
            evidence: S10, S11                                       confidence: medium (could be views instead of tables)

Playlist    id, owner_id, name, description, cover_key (nullable → mosaic), is_public, is_collaborative,
            folder_id (nullable), share_token, created_at, updated_at
            evidence: S09, S17, source 6 (folders)                   confidence: high

PlaylistItem  playlist_id, track_id, position, added_by, added_at
            evidence: drag reorder + "date added" column on S09      confidence: high

Folder      id, owner_id, name, parent_id                            evidence: source 6   confidence: medium

Like        user_id, track_id, created_at                            evidence: S08        confidence: high
LibraryPin  user_id, item_type, item_id, position                    evidence: S07 pins   confidence: medium
Follow      follower_id, followee_id                                 evidence: S20        confidence: medium

PlayEvent   user_id, track_id, played_at, ms_played, context_type, context_id, device_id
            evidence: Recently played, Home shelves, resume       confidence: medium
PlaybackState  user_id, track_id, position_ms, queue (json), context, shuffle, repeat, device_id, updated_at
            evidence: resume across devices / Connect               confidence: guess

Device      id, user_id, name, platform, last_seen                   confidence: guess
Download    user_id, device_id, item_type, item_id, status           (local on device; server keeps entitlement only)  confidence: medium
SearchHistory  user_id, query or item ref, created_at                evidence: S06 recent searches   confidence: medium

Subscription  user_id, provider_customer_id, plan, status, current_period_end, storage_quota_bytes
            evidence: S22, S23, pricing                              confidence: high
            if the apps sell plans: one entitlement per user fed by Stripe, Apple and Google (fixes.md section 7)
Report      id, reporter_email, target_type, target_id, work_description, statement, status, created_at
            evidence: tunebox legal requirement (notice-and-takedown for the launch countries, fixes.md section 7)   confidence: design decision
```

Relationships: User 1-n Track; User 1-n Playlist; Playlist n-n Track via PlaylistItem; User n-n Track via Like; Album/Artist derived per User from Track tags; User 1-1 Subscription; User 1-n PlayEvent; Report → Track | Playlist.

## Feature matrix

See `features.csv`. 73 rows at recon time: must 34, should 17, could 22 (counting skip rows), and 9 of them are skip. `parity.py` counted 60 features, of which 30 were must-haves. `/replica-entrepreneur` added 9 rows and changed notes on existing rows (see `fixes.md`).
Features tunebox adds that Spotify does not have (`original = no`, not counted in parity): metadata editing, storage quota, deleting files, copyright reports.

## Out of scope (cannot or should not be cloned)

- **The music, podcast, audiobook and video catalogue.** It's licensed from labels and publishers. tunebox only plays files the user uploads.
- **Catalogue-wide recommendations** (Discover Weekly, Daily Mix, AI DJ, Talk to Spotify, Taste Profile), **Wrapped** and **Jam/Blend**. They depend on Spotify's catalogue, data and user network. tunebox replaces them with shelves built from the user's own history.
- **Licensed lyrics** (from Musixmatch). We only show `.lrc` files the user provides.
- **Ads business, partner integrations** (cars, speakers, consoles), and the **Studio/remix tools** built on licensed UMG catalogue.
- **Name, logo, green, the Circular font, copy and illustrations.** All replaced in `/replica-design` and `/replica-brand`.

## Legal note specific to tunebox

User uploads = copyright exposure, and streaming them to other people would add more, so v1 does not stream or download one user's audio to another. Before selling it needs: terms of use where users certify their rights; a notice-and-takedown process for each launch country (US: a DMCA agent registered in the US Copyright Office directory, a counter-notice process and a published repeat-infringer policy; EU: Digital Services Act duties; others as counsel advises); a report/takedown flow (F11, S26) where a takedown disables access and keeps the stored copy; no deduplication across users; and tracklist-only sharing (text-only view, recipients play only their own matching copies, rate limits). Details in `fixes.md` section 7. It's not legal advice. Check with a lawyer before launching.

## Size

Screens 27, flows 12, entities 15. Hard parts:
1. **Audio pipeline**: resumable uploads, tag/cover extraction, transcoding to streamable bitrates, signed streaming URLs, storage cost.
2. **Playback engine on 3 platforms**: persistent player, queue/shuffle/repeat semantics, gapless/crossfade, background + lock-screen controls on iOS/Android, resume across devices.
3. **Offline downloads on mobile** (encrypted local cache, sync, entitlement checks) and **payments** across web (Stripe) and app stores (in-app purchase rules for digital subscriptions).

Size: **L** (about a quarter for web + mobile to a sellable v1). Recommended: build nothing beyond a landing page until the gate result is recorded (`fixes.md` section 6); then ship web first with the full core loop, then mobile. Storage is the paid lever: downloads are on every plan and the plan sets the device cap (`fixes.md` F5 and F7). /replica-architect decides on a Subsonic-compatible API before sizing native mobile (`fixes.md` section 5).
