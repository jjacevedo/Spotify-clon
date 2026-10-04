# verify-counts: adversarial recount of fixes.draft.md

Verifier pass, 2026-10-04. Input: `replica/reviews.csv` (read-only). I did not reuse any analyst script, label file or keyword list for the coding. I read the analysts' theme definitions (draft text and `gold.py` notes) only to know what each theme is meant to contain.

## Verdict

The headline numbers hold up. Every figure in the Sample section is exact. 13 of the 16 largest themes come back within ±10% of the draft totals, and the other three within ±13% (bugs +10%, clutter −12%, own +13% once export rows are included). I found no fabricated or unreproducible count. The problems are in the definitions of a few mid-size and small themes, one source split, one thin flag the draft's own rule requires but leaves out, one ranking flip, and one duplicate-text issue:

| # | where in draft | draft says | corrected | why |
|---|---|---|---|---|
| 1 | S2.13 / F2 / Angle B, playlist injection | 33 (25 core + 8 4–5★) · app-store 17, google-play 8, **hacker-news 8** | **30 (21 core + 9)** · app-store 18, google-play 8, **hacker-news 4** | 4 HN rows are outside the definition: 1136 (personalised *editorial* playlists), 1189 (shuffle-button UX, nothing injected), 1209 (autoplay/radio drift), 1215 (pushed into algorithmic playlists). The HN count is wrong by half, and core drops 16% (25 → 21). |
| 2 | S4 U6, discovery missed | "16 HN comments miss catalogue discovery after moving to owned files" | **6** (1037, 1092, 1108, 1137, 1171, 1208) | The other 10 talk about streaming discovery in general: they praise the original's recommendations, want discovery from another streamer, or criticise AI slop. They do not describe missing discovery after moving to owned files. Precision is 6/16. Already marked thin. Fix the sentence; the risk conclusion stands. |
| 3 | S3.3 / F8, library tools | 18 (8 core + **10 4–5★**) · app-store 12 | **14 (8 + 6)** · app-store 9, google-play 1, hacker-news 4 | 4 of the 10 4–5★ rows (151, 625, 726, 910) ask for add-to-playlist or playlist-editing changes. None is one of the named tools (smart playlists, search in playlist, duplicates, tags, scroll bar, pins). −22%. |
| 4 | S2.18, app icon | 18 · "2 sources (app-store 17, hacker-news 1) · not thin" | **17 · app-store only → thin (one source)** | The only HN row (1102) is a 2025 remark about a logo *hue* change inside a UI-churn complaint, not the 2026 icon. By the draft's rule (one source = thin) this theme must be flagged thin. 12 of the 14 core reviews fall in 2026-05/06, a one-event spike like login. |
| 5 | S2.5 / F3, clutter and promos | 49 (46 + 3) · app-store 21, **google-play 4**, hacker-news 24 | **43 (41 + 2)** · app-store 18, google-play 1, hacker-news 24 | 4 rows are free-tier "get Premium" reminders (159, 713, 891, 1107), and 713/891/1107 are one duplicated text. 203 is the Jam invite feature. 397 uses "bloat" to mean slowness. Precision 43/49 = 88%. −12%, and the google-play support falls from 4 to 1. |
| 6 | S2 ranking #2 vs #3 | free-tier control 88 core > bugs 86 core | **bugs ≈92–95 core ≥ free-tier control 88** | The evidence lens under-coded bugs: its list is ~100% precise but has ~90% recall. I accepted all 12 of its extra rows, and 6 of my own 9 extra rows are clear malfunctions. Treat #2 and #3 as tied. In total (core + 4–5★) free-tier control is 117 and bugs 112. |
| 7 | Sample / all GP splits | – | caveat missing | Rows 713, 891 and 1107 (google-play IN listing; dated 2025-08-29, 2026-07-09, 2026-09-15) are near-identical texts (word Jaccard 0.85–0.87). They are counted 3× in free-tier control, ads and clutter, and in the switching intent list. Deduplicated, google-play falls by 2 in each. |
| 8 | S4 U1, self-hosting effort and stacks | effort 17; stacks 17; 4 overlap; 30 distinct | effort **9 strict / 15 broad**; stacks **21**; overlap 8; distinct 28 | The effort definition is loose: 1091 is about the cost of buying music and 1206 about a company's storage cost. The stack count is too low (missed 728, 1068, 1087, 1104). All HN, already thin. Context only. |
| 9 | S3.7, lossless | 11 (9 + 2) · app-store 3; "8 of the 9 core predate 2025-09-10" | **10 (9 + 1)** · app-store 2, hacker-news 8; **7 of 9** predate | 365 and 1162 are equaliser (EQ) requests, not lossless. 1199 is accepted. |
| 10 | S2.26, car | 8 core · 3 sources | **6 core** (+1 4★) · **2 sources** (app-store, hacker-news) | 1010 fails "with CarPlay or not", and 1146 is a playlist switch that happened while driving. Neither is a car-integration problem, and 1146 was the only google-play row. |
| 11 | S2.2 free-tier control, sources and sub-split | hacker-news 1; pick cap 53, order 31 | **hacker-news 0** (2 sources); **pick cap ≈60–62**, order 25–31 | The single HN row (1084) names no lost control. The pick-cap sub-split misses explicit cap rows (121 "certain amount of songs selections per day", 957, 183, 518, 713/891/1107). The ordering of sub-splits is unchanged. |
| 12 | S3.1 upload, 4–5★ part | 34 (30 + 4) · app-store 5 | **31 (30 + 1)** · app-store 2, google-play 1, hacker-news 28 | Core matches exactly. 3 of the 4 4–5★ rows are catalogue wishes (983 "songs that r on youtube", 1053 "merge with Soundcloud") or ambiguous (1027). So the store-side evidence for "upload my files" is 3 rows, and 2 of them are about YouTube music. −9%, under the threshold, but it matters for the "3 sources" wording. |

Everything else is within tolerance (table below).

## Method

1. **Full read, own codebook.** `verify/vdump.py` printed all 1227 rows; I read every one in full and hand-coded `verify/labels.txt` (823 rows carry at least one code; all 594 core rows are labelled). Core rows (rating ≤3, plus every HN comment) were coded for every theme. Rows rated 4–5★ were coded for complaint themes and two praise codes (discovery, background play). Rows are multi-label. Counts are reviews, not people.
2. **Tally.** `verify/vcount.py` counts the labels per theme, with source and core/4–5★ splits, and compares like with like: core-only where the draft says "4–5★ not scanned".
3. **Adversarial overlap and precision.** For each theme I joined my set to the evidence lens's URL list (`synth/recount.json`) on URL and printed every disagreeing row (`verify/vdiff.py`). Then I re-read each one in full: rows only in their list (their possible false positives, or my misses) and rows only in my list. In total this re-read all 208 ads rows, all 116 free-tier rows and every row of every other theme in their lists, far above the 20-per-top-theme minimum. Accept/reject decisions, with reasons, are in `verify/vcorrect.py`. Precision = rows in the evidence list that survive the re-read ÷ list size.
4. **Extras.** `verify/vextra.py` covers the sample section, sub-splits, date splits and shares. `verify/vdupes.py` finds near-duplicate texts. `verify/vswitch.py` counts switching (keyword net of 112 candidates plus rows noticed in the full read, each one read).
5. **Limits.** One coder, no second rater. My recall is not perfect: the evidence lens was right on 3 background-play rows and 12 bugs rows I had missed, and I accepted theirs. Small themes (n < 10) can move by 1–2 rows on judgement alone, so I flag only themes where a row's meaning is clearly outside the stated definition.

## Sample section: all exact

| check | draft | recount |
|---|---|---|
| rows by source | 1028 / 60 / 139 | 1028 / 60 / 139 |
| App Store dates; storefronts nz/us/ca/gb/ie/au | 2026-05-21 → 2026-10-02; 266/233/185/178/106/60 | same |
| App Store rows dated 2026-09 or 2026-10 | 709 | 709 |
| App Store ratings 1–5★ | 235/71/103/132/487 | same |
| Google Play dates; ratings 1–5★ | 2024-09-01 → 2026-09-18; 28/14/4/6/8 | same |
| HN dates | 2023-01-05 → 2026-09-28 | same |
| RSS pages captured (us/nz/gb/ca/ie/au) | 34 (8/8/6/6/4/2) | 34 (8/8/6/6/4/2) |
| core / 4–5★ | 594 (409 + 46 + 139) / 633 (619 + 14) | same |

## Theme by theme

"independent" is my full-read count before adjudication; "corrected" is after re-reading every disagreement. Precision is for the evidence lens's list.

| theme (draft §) | draft n · sources | independent | corrected · sources | precision | verdict |
|---|---|---|---|---|---|
| ads (2.1) | 208 (131+77) · 175/26/7 | 205 (124+81) | 213 (131+82) · 178/29/6 | 206/208 = 99% | OK (+2%) |
| free-tier control (2.2) | 116 (88+28) · 89/26/1 | 114 | 117 (88+29) · 91/26/0 | 113/116 = 97% | OK; HN 1→0; dup ×3 (#7, #11) |
| bugs (2.3, core) | 86 · 72/11/3 | 83 | 95 · 78/13/4 | 86/86 = 100% | OK (+10%); ranking flip (#6) |
| price (2.4) | 82 (62+20) · 70/4/8 | 78 incl. increases | 83 (66+17) · 69/5/9 | 77/82 = 94% | OK; 5 of 20 4–5★ rows aren't "too expensive" (226, 270, 657, 708, 853) |
| price increases (2.4) | 31 (28+3) · 25/1/5 | 32 (29+3) · 25/1/6 | 32 | 31/31 | OK |
| clutter (2.5) | 49 · 21/4/24 | 41 | 43 · 18/1/24 | 43/49 = 88% | flag (#5) |
| UI / redesigns (2.6) | 40 · 21/2/17 | 42 | 41 | 39/40 | OK |
| slow (2.7, core) | 32 · 27/3/2 | 34 | 34 | 32/32 | OK |
| paying and still ads (2.8) | 33 · 22/5/6 | 33 | 33 | 33/33 | OK |
| playback stops (2.9, core) | 28 · 22/5/1 | 28 | 28 | 28/28 | OK |
| recs poor (2.10, core) | 27 · 15/2/10 | 29 | 29 · 15/2/12 | 27/27 | OK (would rank just above playback) |
| offline fails (2.11) | 27 (26+1) · 9/4/14 | 27 | 27 | 27/27 | OK |
| login (2.12, core) | 25 · app-store only, thin | 25 (24 + 1 marginal HN) | 24–25 | 24/25 | OK; 21–22 of them on 2026-09-29 |
| playlist injection (2.13) | 33 (25+6+2) · 17/8/8 | 27 | 30 (21+9) · 18/8/4 | 29/33 = 88% | flag (#1) |
| artist pay / politics (2.14, core) | 23 · 16/1/6 | 24 | 24 | 23/23 | OK |
| catalogue removals (2.15) | 27 (23+4) · 6/2/19 | 26 | 26 | 26/27 | OK |
| billing / support (2.16, core) | 22 · 19/2/1 | 21 | 21–22 | 21/22 | OK |
| shuffle not random (2.17) | 25 (17+8) · 19/1/5 | 26 | 26 | 25/25 | OK |
| app icon (2.18) | 18 · "not thin" | 17 · app-store only | 17 · app-store only | 17/18 | **thin not flagged** (#4) |
| generic paywall (2.19, core) | 15 · thin | 16 | 15–16 | 13/15 | OK |
| devices / Connect (2.20) | 17 · 14/1/2 | 18 | 18 | 16/17 | OK; paywall subset 4 = 4, thin OK |
| AI music (2.21, core) | 13 · 10/–/3 | 14 | 14 | 13/13 | OK |
| queue (2.22) | 16 (13+3) · 7/5/4 | 12 (stricter) | 16 | 16/16 | OK (I accepted all 4 of theirs) |
| rate prompts (2.23) | 12 · thin | 11 | 11 | 11/12 | OK |
| audiobook hours (2.24) | 17 · 14/2/1 | 17 | 17 | 17/17 | OK |
| AI features (2.25, core) | 9 | 9 | 9 | 9/9 | OK |
| car (2.26, core) | 8 · 3 sources | 6 | 6 core · 2 sources | 6/8 | minor (#10) |
| podcast management (2.27, core) | 8 · thin | 9 | 8–9 | 8/8 | OK |
| library data loss (2.28, core) | 7 · 5/2/– | 6 · 5/1/– | 6 | 6/7 (1157 is a playback failure) | OK |
| kids (2.29, core) | 6 · HN, thin | 7 | 6 | 6/6 | OK |
| iPad (2.30) / lock screen (2.31) / travel (2.32) | 4 / 4 / 6 | 4 / 3 / 5 | 4 / 3 / 5 | 4/4, 3/4, 5/6 | OK (lock screen still passes thin, just: 3 reviews, 2 sources) |
| upload own files (3.1) | 34 (30+4) · 5/1/28 | 25 narrow; 31 with Local Files and not-on-streaming | 31 (30+1) · 2/1/28 | 31/34 = 91% | minor (#12) |
| Local Files clunky (3.1) | 11 · –/1/10 | 11 | 11 | 11/11 | OK |
| not on streaming (3.1, market lens) | 18 · 6/–/12 | 11 · 2/–/9 | – | – | the app-store 6 are catalogue gaps; the draft already says so |
| own not rent (3.2) | 30 · 4/2/24 | 27 (+ export 33) | 34 incl. export · 5/2/27 | 30/30 | OK |
| export / transfer (3.2) | 7 · 1/2/4 | 8 · 2/2/4 | 8 | 6/7 | OK |
| library tools (3.3) | 18 (8+10) · 12/2/4 | 13 | 14 (8+6) · 9/1/4 | 14/18 = 78% | flag (#3) |
| history and play counts (3.4) | 9 · 4/–/5 | 8 | 8–9 | 8/9 | OK |
| shuffle-control requests (3.5, fit lens) | 9 · 6/–/3 | 6 named | 6 named, 10 incl. "true random" asks (572, 731, 978, 1169) | – | OK within definition |
| music-only mode (3.6, fit lens) | 10 · 5/–/5 | 4 (narrow) | ≈11 · 3/–/8 on re-read (528, 991, 1022; 1067, 1138, 1143, 1163, 1165, 1199, 1203, 1224) | – | OK total; split differs |
| lossless (3.7) | 11 · 3/–/8 | 9 | 10 · 2/–/8 | 9/11 = 82% | minor (#9) |
| lyrics (3.8) | 3 · thin | 3 | 3 | 3/3 | OK |
| own-files group (U1, core) | 67 · 5/3/59 | – | 69 · 6/3/60 | – | OK (narrow codes only: 58) |
| self-host effort / stacks (U1) | 17 / 17 / 30 distinct | 8 / 21 | 15 broad / 21 / 28 | 15/17 | minor (#8) |
| replaced or converted (U3) | 4 · HN, thin | 2 replaced + 2 conversion notes | 4 | – | OK, but 1206 and 1212 state the conversion neutrally; they aren't complaints |
| offline on other services (U4) | 3 · thin | 2 | 3 (+1220) | – | OK |
| discovery missed (U6) | 16 · thin | 4 | 6 | 6/16 = 38% | flag (#2) |
| kids household (U7) | 6 (market 8) | 7 | 6 | – | OK |
| locked out after cancel (F7) | 3 · 2/–/1 | 3 | 4 · 2/–/2 | – | OK, small |
| gift cards (§7) | 3 · thin | 3 | 3 | – | OK |
| 4–5★ praising discovery | 34 · 31/3 | 33 (31 rated 4–5★) | ≈34 | – | OK |
| 4–5★ praising background play | 13 | 10 | 13 | 13/13 | OK (my misses: 12, 318, 1024) |
| 4–5★ bugs / reliability bucket | 22 | – | 24 (bugs ∪ playback ∪ slow) | – | OK |
| switching away (context) | fit 105 / market 112 / union 125 | – | 78 who left + 29 intending = 107; 112 with conditional threats | – | OK; only 78 actually left |

## Shares and date splits

| claim | draft | recount | verdict |
|---|---|---|---|
| low-rated store reviews in ads, free-tier control or paywall | 185/455 (41%) | 179/455 (39%) | OK |
| core free-tier reviews after 2025-09-15 | 81/88 | 79/86 (92%) | OK |
| core ad reviews that never write ad/ads/advert/commercial | 17/131 | 18/124 | OK |
| login on 2026-09-29 | 22/25 | 21/24 store (+1 marginal HN) | OK |
| core shuffle after 2025-11-13 | 13/17 | 13/17 | OK |
| core offline after 2026-05-28; store 2025–26; HN 2023–24 | 11/26; 12/12; 12/14 | 11/26; 11/11; 12/15 | OK |
| core injection after 2026-05-13 | 13/25 | 13/21 | the share rises (52% → 62%); claim still holds |
| core icon 2026-05 to 06 | 12/15 | 12/14 | OK |
| iPad after 2026-04-16 | 4/4 | 4/4 | OK |
| core queue after 2026-05-28 | 5/13 | 5/13 on the accepted set | OK |
| core lossless before 2025-09-10 | 8/9 | 7/9 | minor |
| free-tier sub-split (core) | pick 53, skip 35, order 31, seek 6, repeat 5, queue 4 | pick 62, skip 33, order 25 (31 incl. "plays a random song"), seek 7, repeat 5, queue 4 | pick cap is undercounted (#11); order of sub-splits is unchanged |

## What to change in the draft

1. **§2.13, F2, Angle B:** playlist injection should read 30 (21 core + 9 4–5★) · app-store 18, google-play 8, hacker-news 4. Optionally move it below politics, removals and billing in the core ranking.
2. **§4 U6:** replace the "16 HN comments…" sentence with: 6 HN comments say they miss recommendations after moving to owned files; another 10 value streaming discovery in general. Keep it thin.
3. **§3.3 and F8:** library tools should read 14 (8 core + 6 4–5★) · app-store 9, google-play 1, hacker-news 4. Drop add-to-playlist requests, or rename the theme to include them.
4. **§2.18:** mark the icon theme **thin (one source, one-event spike)**, like login.
5. **§2.5 and F3:** clutter should read 43 · app-store 18, google-play 1, hacker-news 24, or state that free-tier Premium-upsell reminders are counted (and that 3 of them are one duplicated text).
6. **§2 intro or Caveats:** say that #2 and #3 (free-tier control 88 core vs bugs ≈92–95 core) are a statistical tie. Add the duplicate note: one google-play text (rows 713, 891, 1107) appears three times.
7. Smaller fixes: car 6 core from 2 sources; lossless 10 (app-store 2) and "7 of 9 predate"; free-tier "hacker-news 0, 2 sources" and pick cap ≈60; upload 4–5★ 1 not 4 (store-side upload evidence is 3 rows, mostly YouTube); self-host effort 9 strict / 15 broad, stacks 21.

## Files

- `analysis/verify-counts.md`: this report
- `analysis/verify-counts.json`: independent counts per theme with URL lists, corrected counts with accept/reject ids and URL lists, sample and split checks, switching buckets
- `analysis/verify/labels.txt`: the verifier's hand labels for every row (0-based row id → codes)
- `analysis/verify/vdump.py`, `vcount.py`, `vdiff.py`, `vcorrect.py`, `vextra.py`, `vdupes.py`, `vswitch.py`: run `python3 vcount.py && python3 vcorrect.py && python3 vextra.py` from `analysis/verify/`
