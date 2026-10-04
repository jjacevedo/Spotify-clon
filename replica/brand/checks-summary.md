Note: copied unchanged from the /replica-brand working folder on 2026-10-04 as the record of the name screening. The raw evidence it cites (brand/checks/<name>/, brand/audit/, brand/_full_results.json) stayed in that session's working folder and is not in this repository. The chosen name is Tunehold (see ../brand.md).

# Brand screening: checks summary and top 5

Eight shortlisted names were checked on 2026-10-04 (UTC). The checks covered trademark registers, domains, the two app stores, handles and the web.

**These are screening checks, not legal clearance.** A screening check can miss marks: registers that were blocked, filings too recent to be indexed, and unregistered rights from use. Before money is spent on the name (filings, logo, paid domains, marketing), a trademark lawyer should run a full search. At minimum that means the US, the EU and Colombia (SIC), in classes 9, 42 and 41.

## Bottom line

- **Dropped (3):** Earshelf, Coffer and Holdfast. Each has a blocking conflict (details at the end).
- **Top 5 (all caution, none is a clean keep):** 1 Tunehold, 2 Carriel, 3 Songfold, 4 Kesto, 5 Porti.
- **Recommended: Tunehold.** It is the only finalist with nothing identical in any check that ran, and its exact .com, .net and GitHub name were all free at check time. Its open issue is one pending US application one letter away (TUNEHOOD, class 41). A lawyer can weigh that before anything is spent.

## How to read the tables

- **Status:** `clear` means nothing found in that check. `caution` means an issue to resolve. `conflict` means taken or blocking. `to run` means the check did not run (blocked, or not reached), so nothing is claimed for it.
- **Blocked for every name:** EUIPO and TMview (empty replies or 403), the WIPO Global Brand Database (ALTCHA bot challenge), Colombia's SIC (proxy CONNECT 403), .app/.fm registry RDAP (blocked), .io/.co (rdap.org has no RDAP service for them, which is no answer, not "unregistered"), and X, Instagram and TikTok (proxy 403). None of the EU, global or Colombian registers, the non-.com/.net domains or the three social handles has been checked for any name.
- **Audit:** an independent auditor re-opened the evidence for Carriel, Earshelf, Tunehold and Kesto, and for Porti up to its .com/.net row plus its store, GitHub and label claims. The auditor also re-ran the .com/.net RDAP lookups, the App Store searches and the GitHub user search (about 16:59 to 17:05 UTC). The 16 corrections are applied below and marked **(corrected)**. None changed a verdict.
- **Not audited:** Songfold, Coffer, Holdfast, and Porti's rows after its .com/.net row. The auditor's input was cut off before them. I re-opened the evidence behind the facts that decide those verdicts, and all of it matches the rows:
  - HOLDFAST reg 8036173 (Anvil Studios, Malta; IC 9/28/41/42; live; registered 2025-11-25)
  - COFFR sn 99692561 (Coffr, LLC; filed 2026-03-10; K&L Gates; non-final Office action)
  - songfold.com RDAP (Instra; 2025-05-28 to 2035-05-28; cyon.ch nameservers)
  - SONGBOX reg 7739895 and SONGFLOW! (published 2026-09-15)
  - the GitHub login "songfold"
  - holdfast.com, coffer.com and porti.com RDAP

  The other figures in those rows are as the check agent recorded them.
- Evidence for each name is in `brand/checks/<name>/`. The uncorrected rows, with per-row evidence file names, are in `brand/_full_results.json`.

---

## 1. Carriel: caution

| check | where | status | result | date or "to run" |
|---|---|---|---|---|
| US trademark: CARRIEL and variants | USPTO tmsearch JSON API, all classes | clear | No live CARRIEL mark. The variants search (*carriel*, *karriel*, cariel, carriell, kariel, carrielle, carryel) returned 8 records. Dead: AREPAS EL CARRIEL (regs 5583295 and 5672125, class 30, cancelled 2025). Live but unrelated: CARIEL reg 7830538 (spirits, 32/33) and HOUSE OF KARIEL reg 6997451 (11/24). Nothing in 9/41/42. The phonetic query's top live hits belong to an individual named Karin Carriel (classes 35/41) and are not CARRIEL marks. | 2026-10-04 ~11:11 UTC |
| US trademark: CARRIER in 9/42 | USPTO, carrier* live in IC 9/42, plus exact CARRIER live | caution | 68 live CARRIER marks in 9/42, so the field is crowded. Carrier Corporation owns CARRIER reg 3934036 (class 9, including software for environmental-control displays), reg 5331217 (sensors and alarms) and CARRIER ABOUND reg 7954932 (9/42, building-data software and app), among others, and publishes many Carrier apps on the App Store. Its goods are HVAC, far from music. Still, the name is one letter away and close in English sound to a famous mark. Low-to-moderate risk; for the lawyer's list. | 2026-10-04 ~11:11-11:19 UTC |
| US trademark: CAREL in 9/42 | USPTO | caution | CAREL reg 7452151 is live (CAREL Industries, 9/11/37/42, HVAC controls, including software design in that field). Two other CAREL records are dead. CAREL has HVAC apps on the App Store. Different field, low risk, but phonetically close. | 2026-10-04 ~11:12 UTC |
| US trademark: CARREL/CARRELL | USPTO | clear | 24 records. The live ones are outside software and music: CARREL BOOKS (class 41 publishing), CARRELL medical marks, THE CARRELLE COMPANY (38) and JEFF CARREL (33). None in 9 or 42. | 2026-10-04 ~11:12 UTC |
| EU trademark (CARRIEL, CARRIER, CAREL) | EUIPO eSearch, TMview | to run | EUIPO dropped the connection on the search POST. TMview dropped it three times, then returned 403. Not bypassed. Run by hand in TMview: EM plus national offices, classes 9/41/42. | to run (attempted ~11:12-11:20 UTC) |
| Global | WIPO Global Brand Database | to run | ALTCHA bot challenge, not bypassed. This database covers Madrid filings and the Latin American offices. | to run (attempted ~11:16 UTC) |
| Canada: CARRIEL, CARIEL | CIPO trademark search, all statuses | clear | One record: CARRIEL application 1229461 (leather bags and wallets, Nice 9/18/25), abandoned 2006-05-16. CARIEL: 0. | 2026-10-04 ~11:17 UTC |
| Canada: CARRIER, CAREL | CIPO | caution | CARRIER TMA809197 (Carrier Corp., thermostats and environmental-control software). 51 active marks contain CARRIER. CAREL is registered as TMA1360844 (37/42, HVAC services) and 0884187 (9/11/16). Same assessment as the US. | 2026-10-04 ~11:17-11:18 UTC |
| Colombia: SIC register (any class) | sipi.sic.gov.co, www.sic.gov.co | to run | The proxy refused the connection (CONNECT 403). This is the most important register: Colombia is the home market and "carriel" is a common noun there. | to run (attempted ~11:18 UTC) |
| Colombia: the "Carriel antioqueño" denomination of origin vs software | WebSearch plus Decision 486 art. 135(j); primary sources blocked | caution | From search results only: SIC Res. 72998 of 18 Sep 2025 (announced 7 Nov 2025) protects the denomination of origin "Carriel antioqueño". Art. 135(j) bars marks that reproduce, imitate or contain a protected denomination of origin, even for different products, where there is risk of confusion or association, or an unfair advantage of its notoriety. The protected name is the compound; "carriel" alone is the generic name of the bag. The resolution text was not read because the sources are blocked. A Colombian IP lawyer must confirm. | 2026-10-04 ~11:18-11:19 UTC |
| Domain carriel.com | Verisign RDAP | conflict | Registered: NameSilo, created 2006-04-19, expires 2027-04-19. Nameservers NS1/NS2.AFTERNIC.COM usually mean a for-sale listing; not verified, because the site is blocked. | 2026-10-04 ~11:07 UTC |
| Domain carriel.net and .com alternatives **(corrected)** | Verisign RDAP | caution | carriel.net is registered: created 2026-02-03 through Squarespace, status includes "client hold" (kept out of DNS, but still taken). carrielapp.com, getcarriel.com and carrielmusic.com are not registered: 404 at 11:20 UTC and again at the auditor's 16:59 UTC re-check. | 2026-10-04 11:20 UTC; re-checked 16:59 UTC |
| Domains carriel.app / .io / .co / .fm | rdap.org to registry RDAP | to run | The .app and .fm registry RDAP is blocked, and rdap.org has no RDAP service for .io and .co (no answer). Check at a registrar. | to run (attempted ~11:07-11:21 UTC) |
| App Store | iTunes Search API, software, US/GB/CO | clear | No app named Carriel or anything close. US/GB: 2 unrelated fuzzy hits (4 on the auditor's re-run, normal store drift). CO: 0. | 2026-10-04 ~11:08 UTC |
| Google Play | Play search, en_US/US | clear | 50 results, none Carriel. Nearest titles: Carrel, Carell, Kariel, Carri, Carallel and CAREL's APPLICA. No music app. | 2026-10-04 ~11:08 UTC |
| Handle: GitHub | GitHub MCP user search (REST 403) | caution | The login "Carriel" (id 6644741) is taken. carrielapp and carrielmusic: no users. The org namespace could not be queried, so it is unknown. | 2026-10-04 ~11:08-11:09 UTC |
| Handles: X, Instagram, TikTok | one plain fetch each | to run | The proxy refused all three. Separately, the SoundCloud handle "carrielmusic" is used by DJ Carriel. | to run (attempted ~11:08 UTC) |
| Web | WebSearch | caution | No software or audio brand named Carriel. Artists: Luis Carriel (Apple Music) and DJ Carriel (SoundCloud). "Carriel app" surfaces CAREL HVAC apps, Carallel and Arepas El Carriel (a Bogotá restaurant). Meaning: the Antioquian leather satchel, possibly from English "carry-all"; also a surname. | 2026-10-04 ~11:18 UTC |

**Verdict: caution.** There is no blocking conflict in the US or Canadian registers, the stores or the web. Still open: the home-market questions (SIC unchecked, plus the denomination-of-origin question under art. 135(j)), the Carrier phonetic risk, and carriel.com, carriel.net and the GitHub login, which are all taken.

---

## 2. Earshelf: drop

| check | where | status | result | date or "to run" |
|---|---|---|---|---|
| US trademark: exact and close variants **(corrected)** | USPTO tmsearch JSON API | clear | No EARSHELF filing, live or dead. Exact/plural: 0. *earshelf*: 1 record (CLEARSHELF 86491720, class 9, dead). Variants (earshell, hearshelf, *earshel* and others): 3 records: CLEARSHELF (dead), CLEARSHELL (Maui Jim sunglasses, live) and UEARSHELP (reg 7540395, class 10 hearing aids, live). Phonetic query (511 hits): AIRSHIELD is 1st, AIRESHIELD 17th, AEROSHIELD 25th; none is for audio. SHELFPLAYER, AUDIOBOOKSHELF and SHELF PLAYER: 0. Filings from the last few days may not be indexed yet. | 2026-10-04 ~11:12-11:13 UTC |
| US trademark: SHELF-formatives in 9/41/42 | USPTO | caution | 168 live SHELF marks, so the element is crowded and weak. Closest in media: SHELF by Koodos, Inc. in class 9, with 97811467 approved for publication (software to showcase media users listen to, read or watch) and 50130482 a new application (tracking books, movies, TV, music, podcasts). Koodos also runs the Shelf iOS app. Others: THE SLEEPY BOOKSHELF 97788535 (9/41/42, audiobooks), BOOKSHELF/BOOKSHELF+ (VitalSource), SHELFBOUND, CLOUDSHELF 86819429 and SHELFORD (Rupert Neve, mixers). None contains EAR. | 2026-10-04 |
| US trademark: EAR-formatives in class 9 (audio) and class 10 (hearing) **(corrected)** | USPTO | clear | Class 9 has 895 live WM:ear* marks. About 167 are EAR-first (excluding EARTH/EARLY/EARN words), and about 132 of those name audio, music or sound goods, e.g. EARPLAY 7455026, EARSHOTS 6603638, EARSENSE 7943014, EARCLOUD 6423002, EARMASTER 3511422 and EARCANDY 8145581. Class 10: 259 live, 115 EAR-first. No EAR+SHELF mark in either class. Closest by look: UEARSHELP (reg 7540395) and EAR SHIELD (reg 4897476), both class 10. | 2026-10-04 ~11:13 UTC |
| EU trademark | EUIPO eSearch, TMview | to run | The EUIPO search POSTs got empty replies (twice). The TMview API got an empty reply and its home page returned 403. Not bypassed. | to run (attempted ~11:13-11:14 UTC) |
| Global | WIPO Global Brand Database | to run | ALTCHA bot challenge. | to run (attempted ~11:16 UTC) |
| Canada | CIPO | clear | EARSHELF in all fields: 0. EARSHELL: 0. EARSH*: 1 (EARSHADES 1059534, class 9, expunged). The BOOKSHELF sanity query returned 10, so the endpoint works. About 38 live SHELF marks in 9/41/42, none with an EAR prefix. | 2026-10-04 |
| Domain earshelf.com | Verisign RDAP | conflict | Registered 2026-09-28T17:17:18Z, six days before the check. GoDaddy, expires 2029-09-28, all client locks on. Registrant not visible. That is one day before the first commit of the same-name GitHub project. | 2026-10-04 |
| Domain earshelf.net | Verisign RDAP | clear | 404, no registration record. | 2026-10-04 |
| Domains earshelf.app / .io / .fm | rdap.org to registry RDAP | to run | The registry RDAP hosts are blocked; .io has no RDAP service. | to run (attempted ~11:08 UTC) |
| App Store (US, GB) | iTunes Search API | clear | No Earshelf. The results are EAR apps (hearing aids, earbuds, ear trainers). Neighbours: "AudioShelf: Music & Books" and "Shelf: music, books, movies" (Koodos). | 2026-10-04 |
| Google Play (US) | Play search | clear | 30 apps, none Earshelf, all EAR-prefixed. Nearest: "Earleaf - Audiobook Player". | 2026-10-04 |
| Handle: GitHub **(corrected)** | GitHub user search; WebFetch github.com/earshelf | clear | github.com/earshelf returned 404 and the user search returned 0, so no user or org holds the name. The repo imwithoutlimits/earshelf is covered in the Web row. | 2026-10-04 11:09 UTC; re-checked ~17:00 UTC |
| Handle: X | x.com/earshelf | to run | Proxy CONNECT 403. | to run (attempted 11:08-11:18 UTC) |
| Handle: Instagram | instagram.com/earshelf | to run | Proxy CONNECT 403. | to run (attempted 11:08-11:18 UTC) |
| Handle: TikTok | tiktok.com/@earshelf | to run | Proxy CONNECT 403. | to run (attempted 11:08-11:18 UTC) |
| Web: brand in audio or software | WebSearch; WebFetch of the repo | conflict | github.com/imwithoutlimits/earshelf calls itself a "Personal document-to-audio library": a React/Vite PWA with a playback engine, Supabase, ElevenLabs/Kokoro voices, and Free/Plus/Pro plans billed through Lemon Squeezy. 11 commits, first 2026-09-29, latest 2026-10-01 (adds API deployment config). Not in the stores yet. Same name, audio playback, sold by subscription, so it overlaps 9/42. | 2026-10-04 |
| Meaning | WebSearch | clear | No dictionary entry. The nearest word is "earshell" (abalone, or an earmold). Nothing awkward in English; other languages not checked. | 2026-10-04 |
| Colombia (SIC) | sipi.sic.gov.co | to run | Proxy CONNECT 403. | to run (attempted 2026-10-04, at or before 11:18 UTC) |

**Verdict: drop.** The registers that ran are clean, but earshelf.com was registered on 2026-09-28. On 2026-09-29 an identically named audio-playback subscription app started on GitHub. One thing would reverse this: if the founder registered earshelf.com or owns that repo. Confirm before discarding the name for good.

---

## 3. Tunehold: caution

| check | where | status | result | date or "to run" |
|---|---|---|---|---|
| US trademark | USPTO tmsearch JSON API plus TSDR | caution | No TUNEHOLD mark, live or dead. Variants (*tunehold*, toonhold, tunhold, tuneholder, tunehould and others): 0. "tune hold" as a phrase: 0. The TUNEIN control returns hits, so the queries work. **Closest: TUNEHOOD, sn 99899715**, a live pending application filed 2026-06-23 by Tunehood LLC (St. Petersburg, FL; has an attorney). It covers class 41, a music and entertainment information and music-discovery website, and is still awaiting examination. It is one letter away and in music. TUNE- is crowded: 212 live marks in 9/42 coexist, including TUNEPLAY reg 6311157, TUNEGO, TUNEFIND, TUNEBAT, TUNELY (pending), TUNEKIT, TUNEBOXED reg 8405385 and TUNEPILOT. HOLD-formatives near audio (727 live in 9/41/42): HOLDTONES sn 99902956 (pending, 9/38, ringtone app), HOLDSOUND reg 6794854 (headphones), IRON HOLD reg 4600322, HOLDMYVOICE (pending), LEAVE ME ON HOLD (on-hold audio). None is identical, and none is a music player or locker. TUNELOCKER is dead. | 2026-10-04 ~11:22-11:25 UTC |
| EU trademark | EUIPO eSearch, TMview | to run | Both endpoints returned an empty reply. Search TUNEHOLD and TUNEHOOD in 9/41/42 by hand. | to run (attempted ~11:24 UTC) |
| Global | WIPO Global Brand Database | to run | ALTCHA bot challenge, not solved. | to run (attempted ~11:24 UTC) |
| Canada **(corrected)** | CIPO JSON API | clear | No hits for "tunehold" (all fields, all statuses), "tune hold", TUNEHOOD or tuneh*. The TUNEIN control returned 3. TUNE*: 134 active, 68 in 9/38/41/42. *HOLD*: 704 active in 9/41/42 (first 500 returned). The on-hold audio marks among them are TELEHOLD 0577143 (41), ON HOLD IMPRESSIONS 1033924 (38/41/42) and On Hold Impressions & Design 1092041 (35/38/42). None combines HOLD with TUNE, and none is a music player. | 2026-10-04 ~11:24-11:25 UTC |
| Domains | Verisign RDAP; rdap.org | caution | **tunehold.com is not registered** (404; the tunebox.com control returned 200). Also 404: tunehold.net, tuneholdapp.com, tunehold-app.com and gettunehold.com. The auditor's re-check at ~16:59 UTC still got 404. tunehold.app and .fm are blocked; .io and .co have no RDAP service. Those four are to run. | 2026-10-04 11:20 UTC; re-checked ~16:59 UTC |
| App Store **(corrected)** | iTunes Search API: US/GB/CO, iPad, Mac, "Tune Hold", "Tunehood" | clear | No Tunehold or anything close. US and GB: 25 fuzzy hits each (tuners and metronomes). CO: 0. "Tune Hold": 49 (tuners plus DistroKid). Mac: 21 (TuneIt, TuneHertz, TuneWave). No title contains "hold" or "tunehood". The auditor's re-run (US 49, GB 48, CO/FI/ES 0) found no Tunehold app either. | 2026-10-04 11:21 UTC; re-run ~17:00 UTC |
| Google Play | Play search, en_US/US | clear | A single unrelated result ("Platformer Gamepad"). | 2026-10-04 11:21 UTC |
| Handles | GitHub (web, MCP search); X, Instagram, TikTok | caution | github.com/tunehold returned 404 (the auditor confirmed it), and the user and repo searches returned 0. X, Instagram and TikTok: proxy CONNECT 403, so to run. | 2026-10-04 ~11:22-11:31 UTC |
| Web | WebSearch | caution | No brand, app or site named Tunehold, and tunehold.com is not indexed. Search engines map the word to "toehold". Tune- neighbours: TuneIn, Tuneo, TuneHere, TuneHue, Tunepal. "Hold" next to music strongly evokes telephone hold music (no "TuneHold" service exists). Tunehood is live at tampa.tunehood.com with a TM symbol, matching the US application. | 2026-10-04 ~11:22-11:30 UTC |
| Name-specific: TUNEHOOD and HOLD-formatives | USPTO plus TSDR, CIPO, App Store, web | caution | TUNEHOOD is one letter away, sounds close and is in music. A lawyer should weigh it for class 41, and possibly for 9/42. It is not in CIPO or the App Store. HOLDTONES and HOLDSOUND put the words in the opposite order and cover different goods. | 2026-10-04 ~11:24-11:30 UTC |
| Colombia (SIC) | sipi.sic.gov.co | to run | Proxy CONNECT 403. | to run (attempted ~11:24 UTC) |

**Verdict: caution.** Nothing identical turned up in any check that ran. To resolve: TUNEHOOD (pending, class 41, one letter away) and the weak, crowded TUNE- stem, which leaves HOLD to carry the mark. The "hold music" reading is a positioning risk, not a legal one.

---

## 4. Kesto: caution

| check | where | status | result | date or "to run" |
|---|---|---|---|---|
| US trademark (exact plus close variants) | USPTO tmsearch JSON API | caution | Exact KESTO: 3 records, none live in 9/41/42. KESTO 76326543 (Kesto America, class 9 direction finders) is dead, abandoned 2004-01-22. KESTO STEELING 99667176 is live but in class 21 (kitchenware). KESTO KITCHEN AID 98833456 is dead. An owner search for "jotika" returned 0, so Jotika's app has no US mark. Close live marks in 9/41/42: KESTE reg 3211364 (Keste LLC, class 42 software consulting, one letter off), KESTE reg 7009856 (class 9 anemometers and radios), KESITO 88863511 (9), KESTY AI 98911913 (42), KASTO reg 6056140 (41, an individual's musical act), KESTRA 98294145 (9/42 workflow software) and many KESTREL marks. No live KESTO mark for music or audio. | 2026-10-04 11:23 UTC |
| EU trademark | EUIPO eSearch, TMview | to run | The EUIPO JSON POST got an empty reply. TMview returned 403, and its API POST got an empty reply. This is the key open check, because "kesto" is a Finnish dictionary word. | to run (attempted 11:25 UTC) |
| Finnish register (dictionary word) | PRH tavaramerkkitietopalvelu.prh.fi | to run | Proxy CONNECT 403. Language finding from web search: "kesto" means duration or durability, and Finnish music interfaces use it as the label for track and playlist length (Apple Music fi: "Kesto: 5 tuntia 48 minuuttia"). That is a descriptiveness risk for music goods in Finland and the EU, and Finnish users would read the app name as "Duration". | to run (attempted 11:27 UTC) |
| Global | WIPO Global Brand Database | to run | ALTCHA bot challenge. | to run (attempted 11:25 UTC) |
| Canada | CIPO plus detail page | clear | KESTO TMA592604 (Kesto America, class 9 telecom) was expunged 2019-05-30. KESTOS (25, clothing) is registered but unrelated. KESTE: one expunged (35/42/45), one approved (11), and Kestè Pizza e Vino (43). KASTO 0835220 is registered in classes including 9/42 (KASTO Maschinenbau, industrial). No live KESTO in 9/41/42. | 2026-10-04 11:24 UTC |
| Domains | Verisign RDAP; rdap.org | conflict | kesto.com is registered (GoDaddy, 2004-07-10, expires 2028-07-10; per web search, a now-closed UK click-and-collect grocery). Also registered: kesto.net (NameCheap, 2004), kestoapp.com (IONOS, 2017) and getkesto.com (Squarespace, 2026-07-15). kestomusic.com: 404. kesto.app, .fm and .fi are blocked and kesto.io has no RDAP service, so all four are to run. Jotika's seller URL is www.kesto.io, so .io is very likely registered (unverified). | 2026-10-04 11:25 UTC; re-checked ~16:59 UTC |
| App Store (US, GB, FI) **(corrected)** | iTunes Search API plus lookup | caution | Three listed apps share the exact name; none is a music player. Kesto id1549147314 (Jotika LLC, Lifestyle) had its last version on 2023-12-29 and lists www.kesto.io as seller URL; it is still listed, although reports say it was terminated 2025-11-01. Kesto: Couples Budget id6787574571 (Finance) launched 2026-08-17, and Kesto — Daily Puzzle Challenge id6768055870 (Games) on 2026-05-15. "Kesto Business" id1574834392 appears only as a web-search link and returns nothing in any storefront checked, so it is likely delisted (unverified). The auditor's re-run found all three in US/GB/CO and two in FI/ES. | 2026-10-04 11:26 UTC; re-run ~17:00 UTC |
| Google Play | Play search plus details?id=com.jotika.kesto | caution | Top result: Kesto — Daily Puzzle Challenge (tw.playground.kesto). Jotika's com.jotika.kesto returns 404 (delisted; the auditor confirmed). No music app named Kesto. | 2026-10-04 11:26 UTC |
| Handles | GitHub (REST, MCP, WebFetch); X, Instagram, TikTok | caution | GitHub "kesto" is taken by a dormant org (one Erlang repo, last updated 2013-06-03). X, Instagram and TikTok: proxy 403, to run. From web search: X @Kestico_ uses the display name "Kesto", soundcloud.com/kesto is an artist, and facebook.com/kestoapp is Jotika's. | 2026-10-04 11:26 UTC |
| Web | WebSearch | caution | No audio or music software brand named Kesto; the closest audio software is Kaseto, a desktop player. In music: the artist Kesto (Apple Music, Last.fm, SoundCloud), Pan Sonic's 2004 album "Kesto" and a Bandcamp track. Jotika's app included music and video, and its founder announced the shutdown in Nov 2025. No "Kesto Oy" software company. | 2026-10-04 11:27 UTC |
| Colombia (SIC) | sipi.sic.gov.co | to run | Proxy CONNECT 403. | to run (attempted 11:28 UTC) |

**Verdict: caution.** No live KESTO mark in 9/41/42 in the US or Canada. To resolve: the EU and Finland are unchecked, and "kesto" is the Finnish word for "duration" used in music interfaces, so it may be descriptive there. There are three other exact-name apps (none in music), and nearly every .com variant is taken.

---

## 5. Porti: caution

| check | where | status | result | date or "to run" |
|---|---|---|---|---|
| US trademark **(corrected)** | USPTO tmsearch JSON API, all classes and live in 9/41/42 | clear | No PORTI or PORTÍ word mark, live or dead. Variants search: 10 hits. Dead: PORTIE 99223032 (25/18), SKI*PORTY, PORTY-T. Live but unrelated: PORTI-BOY reg 0870153 (embalming machines), SKIPORTY (18/25) and $PORTIE $HORTIE$ reg 8384269 (41, reality TV). The owner search for porti / porti music returned 0 (the control "neve" returned 65). PORTI* live in 9/41/42: 60 marks, all different words: PORTIFY 8081724 (UK owner, business software), PORTIFY 98938981 (chargers, pending), PORTICO 7892029 (Rupert Neve, recording gear), PORTIVE 99734934. Sound-alikes: PORTE and PORTE DEBIT (Populus, pending, 9/36/42), FORTI 6200750 (chat app) and PORTA PRO 3746791 (Koss headphones). | 2026-10-04 11:27 UTC |
| EU trademark | EUIPO eSearch, TMview | to run | The EUIPO search POST got an empty reply. TMview returned 403 and an empty reply. This check matters most for Porti, because PORTi (a Spanish delivery app) and porti.com (Italian nameservers) suggest use in the EU. | to run (attempted 11:29 UTC) |
| Global | WIPO Global Brand Database | to run | ALTCHA bot challenge. | to run (attempted ~11:29 UTC) |
| Canada | CIPO | clear | Trademark field "porti": 0. All fields: 2 (PORTiFi 1862706, 9/38, abandoned; PORTIPLAY 0492372, 9, expunged). PORTI*: 125, all different words (PORTIFY 2370842 pending in 9/35/36/38/42, PORTIA, PORTICO, PORTICA, PORTIX). | 2026-10-04 11:28 UTC |
| Domains porti.com / .net and variants | Verisign RDAP | conflict | porti.com is registered: created 2000-02-08, Ascio, expires 2027-02-08, Tiscali (Italy) nameservers; the site is blocked. Also registered: porti.net (2000, Tucows), portiapp.com (2025-11-10, Squarespace; expires 2026-11-10), getporti.com (2025-01-10, Porkbun) and portimusic.com (2017, GoDaddy, parked for sale at Afternic). tryporti.com: 404. | 2026-10-04 11:29 UTC; re-checked ~16:59 UTC |
| Domains porti.app / .io / .fm / .co | rdap.org to registry RDAP | to run | .app and .fm are blocked; .io and .co have no RDAP service (no answer). | to run (attempted 11:29 UTC) |
| App Store **(corrected)** | iTunes Search API, US/GB/ES/CO (plus FI on re-run) | caution | **Portí** id6737745481 (PORTI SAUDE E TECNOLOGIA LTDA, Finance, porti.digital; a fintech for doctors' shifts and income) is listed in US, GB, CO, ES and FI. FI also lists "Portí Pay" from the same seller. **Porti** id1490891065 (GORUNUM TASARIM, Games) is in GB, CO and FI. No music or audio app is named Porti. The music-artist search lists about 10 artists named Porti, plus "Porti Music" (Reggae, id1214642711). | 2026-10-04 11:30 UTC; re-run ~17:00 UTC |
| Google Play **(corrected)** | Play search (US) plus direct detail pages | caution | The US search page has one exact match, com.gt.porti "Porti" (GÖRÜNÜM TASARIM, Arcade); near ones are Porty, Teleporti and Porte. Direct detail-page fetches (auditor, HTTP 200) found two more: com.porti "Portí" (Porti Dev, Productivity) and es.hiopos.porti "PORTi - Delivery & Take Away" (ICG Software, Food & Drink). No music app. | 2026-10-04 11:30 UTC; detail pages ~17:00 UTC |
| Handle: GitHub | GitHub MCP search; WebFetch github.com/porti | conflict | The login "porti" (id 12827258) is taken by a personal account with 8 repos, including "songseeker" (a music guessing game). This is a handle conflict only, not a trademark issue. Whether portiapp and portimusic are free was not determined (REST 403). | 2026-10-04 11:31 UTC |
| Handles: X, Instagram, TikTok | x.com/porti, instagram.com/porti, tiktok.com/@porti | to run | The proxy blocked all three. Web search shows Instagram @portimusic is held by Porti Music, LLC. @porti itself was not checked. | to run (attempted 11:31 UTC) |
| Web | WebSearch | caution | Porti Music, LLC is a reggae label tied to Jamaica, with Instagram @portimusic (~18K followers per the snippet), SoundCloud, Facebook and an Apple Music page. Several artists use "Porti". Porti Company (Dallas; per the snippet, software and record production; site does not resolve). Apps: Portí (Brazil, 3,000+ doctors), PORTi (Spain, HIOPOS), the Porti game, Portio, Portia Pro. No audio-software brand named Porti. Meaning: Latin/Italian "harbours", Italian "(you) carry", Esperanto "to carry"; also minor Nigerian Pidgin slang for badly cooked food. | 2026-10-04 11:31 UTC |
| Judge note: does Porti Music hold a mark? | USPTO owner search; web; EU/WIPO blocked | caution | No US filing (owner search: 0), and no trademark record in web search. EU, WIPO and Jamaica (JIPO) not checked. The label's unregistered use in music (records, social handles) is a risk under rights from use, not a registered block. | 2026-10-04 11:28 UTC |
| Judge note: PORTÍ (accented) and the Portí app's owner | USPTO, CIPO, App Store, web | caution | No PORTÍ mark at the USPTO or CIPO. The owner is PORTI SAUDE E TECNOLOGIA LTDA (Brazil). Brazil's INPI was blocked, so a likely INPI filing is to run. | 2026-10-04 11:28-11:32 UTC |
| Colombia SIC / Spain OEPM / Brazil INPI | sipi.sic.gov.co, consultas2.oepm.es, busca.inpi.gov.br | to run | Proxy CONNECT 403 on every host. | to run (attempted 11:32 UTC) |

**Verdict: caution.** The US and Canadian registers are clean. To resolve: exact-name apps outside music (Portí fintech, PORTi delivery, the Porti game); a reggae label using the identical name in music (unregistered); porti.com and four variants taken; and the EU, Brazil and Spain registers unchecked.

---

## 6. Songfold: caution (not audited; key facts spot-checked)

| check | where | status | result | date or "to run" |
|---|---|---|---|---|
| US trademark | USPTO tmsearch JSON API plus TSDR | clear | No SONGFOLD mark. Exact and variants (songfolds, song fold, song-fold, songfolder, sonfold, songfeld, songphold, songfold music/app): 0. SONGF*: 44, none SONGFOLD. Closest live SONG marks in music software: **SONGFLOW!** (Audiospot LLC, sn 99732252 and 99804386, class 9 recording, songwriting and playback app; published for opposition 2026-09-15) and **SONGBOX** (Songbox Technologies, reg 7739895, 9/42, software for storing and sharing music files, which is our goods). Also SONGPAD reg 7164423, SONGSHIFT sn 99330927 (pending) and SONGDRIVE sn 99350191 (pending). 357 live SONG-formatives in 9/42, so SONG is weak. FOLD: 357 live in 9/41/42. No FOLDPLAY, FOLD MUSIC, TUNEFOLD or FOLDSONG. MUSICFOLD 86601270 is dead. Live: UNFOLD reg 7592989 (audio-processing software), FOLD reg 6092581 (bitcoin payments) and FLIPFOLDER (sheet-music SaaS). | 2026-10-04 11:30-11:37 UTC |
| EU trademark | EUIPO eSearch, TMview | to run | The EUIPO JSON POST dropped the connection; the TMview API failed with SSL_ERROR_SYSCALL. FOLD Production Music (London, a production-music library since 2021) may hold FOLD in the UK or EU and must be checked by hand. | to run (attempted 11:33 UTC) |
| Global | WIPO Global Brand Database | to run | ALTCHA bot challenge. | to run (attempted 11:33 UTC) |
| Canada | CIPO | clear | "songfold" in all fields: 0. songfo*: 0. "song fold": 0. FOLDPLAY, SONGBOX, SONGFLOW and FOLDMUSIC: 0 each. songf*: 6, none close (SONGFIRE reg 1501358, SONGFLAME, songful; SONGFILE and SONGFINDER dead). MUSICFOLD 1750705 is abandoned. 314 active *fold* marks in 9/41/42, none a music player. The control "songbird" returned 20. | 2026-10-04 11:32 UTC |
| Domains | Verisign RDAP; rdap.org | conflict | **songfold.com is registered to a third party**: created 2025-05-28, Instra Corporation, expires 2035-05-28 (a 10-year term), nameservers ns1/ns2.cyon.ch (a Swiss host). Content not visible (proxy). Not registered: songfold.net, songfoldapp.com, getsongfold.com, songfoldmusic.com and trysongfold.com. .app and .fm are blocked; .io and .co have no RDAP service; all four are to run. | 2026-10-04 11:33 UTC |
| App Store | iTunes Search API, US/GB, plus "Song fold" and "Foldplay" | clear | No Songfold or anything close. US 24 and GB 22 results, all generic music apps. "Foldplay" returns only origami and puzzle games, so the Foldplay music player is not on iOS. | 2026-10-04 11:34 UTC |
| Google Play | Play search plus 2 detail pages | caution | No Songfold. Two FOLD music apps: "Foldplay: Folder Music Player" (net.pnhdroid.foldplay, 100K+ downloads, updated 2026-09-11), a direct goods neighbour, and "Gatefold.fm: Vinyl Collection". Also "SongFlow - Music Player" (100+ downloads, last updated Aug 2024). None is near-identical. | 2026-10-04 11:34 UTC |
| Handles | GitHub (MCP search); X, Instagram, TikTok | caution | GitHub "songfold" is taken (id 128128919; profile not viewable). X, Instagram and TikTok: proxy 403, to run. Web search found no songfold account on SoundCloud, Instagram, TikTok or X. | 2026-10-04 11:35 UTC |
| Web | WebSearch | caution | No brand, product or meaning for Songfold, and nothing awkward. The nearest live brand is **SongFolder by Songtools** (songtools.io/songfolder), cloud storage for song assets including mp3s, aimed at music marketing. It is close in look and goods, but has no US or Canadian registration (USPTO "songfolder": 0). Others: SongFolio, SongFlow, FlipFolder, Foldplay, FOLD Production Music (@fold.music), Folded Music and Soundfold (acoustic panels). | 2026-10-04 ~11:35-11:37 UTC |
| Name-specific: FOLD and SONG formatives | USPTO, CIPO, Play, web | caution | No FOLDPLAY or FOLD MUSIC mark in the US or Canada. The closest overall impressions are SONGFLOW!, SONGBOX and SongFolder. All share the SONG prefix with a different second element, and none is identical. Both elements are crowded. | 2026-10-04 11:31-11:37 UTC |
| Colombia (SIC) and UK IPO | sipi.sic.gov.co, trademarks.ipo.gov.uk | to run | Proxy CONNECT 403. | to run (attempted 11:36 UTC) |

**Verdict: caution.** Nothing identical was found. To resolve: songfold.com is held by a third party on a long term, the GitHub login is taken, and the close SONG- neighbours (SONGBOX, registered for music-file storage; SONGFLOW!, published; SongFolder, unregistered) leave a weak mark in a crowded field.

---

## 7. Coffer: drop (not audited; key facts spot-checked)

| check | where | status | result | date or "to run" |
|---|---|---|---|---|
| US trademark | USPTO tmsearch JSON API plus TSDR; COFFER, *coffer*, variants COFFR/KOFFER/KOFER/COFER/KOFR/COFFRE | conflict | No live COFFER word mark. The only plain COFFER (reg 4194017, class 25) was cancelled 2019-03-22. **Blocking: COFFR, sn 99692561** (Coffr, LLC, Austin TX; filed 2026-03-10; counsel K&L Gates) is a live application in 9/36/42 for downloadable and SaaS payment software, under examination (non-final Office action 2026-07-22). It sounds the same as COFFER and was filed earlier, so an examiner would likely cite it against our class 9 filing. Also live: COFFERSY (pending, 42), plus unrelated COFFERGY, ECOFFER, COFFERLOK and C COFFERHUB FINANCE. | 2026-10-04 11:34 UTC |
| EU trademark | TMview, EUIPO eSearch | to run | TMview: SSL_ERROR_SYSCALL and an empty reply. EUIPO JSON endpoint: empty reply. | to run (attempted 11:36 UTC) |
| Global | WIPO Global Brand Database | to run | ALTCHA bot challenge. | to run (attempted 11:36 UTC) |
| Canada | CIPO, all statuses | clear | No COFFER mark in any status. Only COFFERTEK (6), VISU-TURN COFFERS (abandoned), COFFERCOUSTIC (expunged) and French coffre/coffret marks (COFFRE-FORT 41, COFFRES AUX TRÉSORS 9/28). Nothing identical in 9/41/42. | 2026-10-04 11:35 UTC |
| Domains | Verisign RDAP; rdap.org | conflict | coffer.com registered since 1997-07-15 (pair Networks). coffer.net since 2003 (Moniker). cofferapp.com (2025, Porkbun, in redemption). getcoffer.com (2026-07-01, Gname). coffermusic.com: 404. .app/.fm/.io/.co to run. | 2026-10-04 11:36 UTC |
| App Store | iTunes Search API, US/GB/CO | conflict | At least six live exact-name apps: Coffer: Money Tracker, Coffer Crypto Portfolio, Coffer - Collectables (US); Coffer: Souvenir Journal, Coffer: Receipt Tracker, Coffer: Subscription Tracker (GB); plus a developer named Coffer Internet Services (CO). None is a music app. | 2026-10-04 11:37 UTC |
| Google Play | Play search plus 2 detail pages | conflict | Five matches, including the exact-name "Coffer" (com.romeo.cofferapp, Finance), "Coffer: Portfolio Tracker" (Coffer Labs), "Coffer Offline Password Vault", "Coffers" and "Coffer: Offline Journal". None is a music app. | 2026-10-04 11:37 UTC |
| Handles | GitHub (MCP, WebFetch); X, Instagram, TikTok | conflict | GitHub "coffer" is taken (user id 3670728), along with many variants. X, Instagram and TikTok: proxy 403, to run. | 2026-10-04 11:38 UTC |
| Web | WebSearch | caution | No music app named Coffer (only artist names). The software space is crowded with Coffer finance and privacy products: coffer.to, coffer.finance, a Coffer Chrome extension, the self-hosted 2FA vault Coffer, and a macOS Coffer. The COFFR applicant runs getcoffer.com. "Coffer" is a dictionary word for a chest for valuables, which makes it weak and descriptive for a storage app. | 2026-10-04 11:38 UTC |
| Name-specific: COFFR / KOFFER / COFER | USPTO, CIPO | conflict | COFFR (99692561) is a live, pending application in 9/42. No registered COFFER or COFFR mark in 9/42 in the US or Canada. KOFFER and KOFER cover luggage and bags; COFERY covers sunglasses. | 2026-10-04 11:35 UTC |
| Colombia (SIC) | sipi.sic.gov.co | to run | Proxy CONNECT 403 (UK IPO also blocked). | to run (attempted 11:39 UTC) |

**Verdict: drop.** COFFR is an earlier-filed, phonetically identical application for software in 9/42. On top of that come six or more exact-name live apps, every useful domain is taken, and the word is a weak dictionary term.

---

## 8. Holdfast: drop (not audited; key facts spot-checked)

| check | where | status | result | date or "to run" |
|---|---|---|---|---|
| US trademark (exact plus variants) | USPTO tmsearch JSON API | conflict | **Blocking: HOLDFAST reg 8036173** (sn 97914391; registered 2025-11-25; live). Owner: Anvil Studios Limited (Malta), maker of the game "Holdfast: Nations At War". Classes 9 (downloadable game software), 41, 42 (software development, gaming SaaS/PaaS) and 28. That is the identical word, for software, in the classes we would file. Other live marks: HOLDFAST (Bel-Art, lab ware), HOLDFAST LLC design (camera straps), HOLD FAST (camera bags), HOLDFASTPRO (phone holders), and HOLD FAST FEATURES / HOLDFAST COACHING / HOLD FAST FITNESS in 41. 96 hits across all classes. | 2026-10-04 11:38 UTC |
| EU trademark | EUIPO eSearch, TMview | to run | Both backends returned empty replies. Anvil is in Malta, so a HOLDFAST EUTM is likely. | to run (attempted 11:40 UTC) |
| Global | WIPO Global Brand Database | to run | ALTCHA bot challenge. | to run (attempted 11:40 UTC) |
| Canada | CIPO, all statuses | clear | No HOLDFAST in 9/41/42. Six HOLDFAST records in other classes (3, 5, 6/19, 10/17, 32). "hold fast": one abandoned (25). The TUNEIN control returned 3. | 2026-10-04 11:39 UTC |
| Domains | Verisign RDAP; rdap.org | conflict | holdfast.com (2003, Network Solutions), holdfast.net (1998), holdfastapp.com (2025) and getholdfast.com (2025, Afternic, likely for sale) are all registered. holdfastmusic.com: 404. .app/.fm/.io/.co to run. | 2026-10-04 11:40 UTC |
| App Store (US, GB) | iTunes Search API | conflict | 15 US / 14 GB results, many exact-name. **"Holdfast: Ambient Sounds"** (Myworkingmemory LLC, id 6762058537, genres Health & Fitness and Music) is an exact-name audio app. Over a dozen others, mostly fitness. | 2026-10-04 11:41 UTC |
| Google Play | Play search plus 1 detail page | caution | HoldFast (project tracker), Holdfast Recovery, Holdfast Strength & Cond., Holdfast - Abstinence Counter, Holdfast: Fasting Timer. No music app. | 2026-10-04 11:42 UTC |
| Handle: GitHub | REST/web (403), MCP user search | to run | No user is exactly "holdfast" (49 near logins, including holdfastmusic). Whether an org exists is unknown. Do not treat it as available. | to run (partial result 11:42 UTC) |
| Handles: X, Instagram, TikTok | one plain fetch each | to run | Proxy 403. The game uses @holdfastgame. | to run (attempted 11:42 UTC) |
| Web | WebSearch | conflict | "Holdfast" + music returns the game, which has an in-game music player and a soundtrack sold on Steam. Also: Holdfast Wealth Management, the City of Holdfast app (AU), the archived observability project BrewingCoder/holdfast, and the band "Holdfast." (Colorado). No music-streaming product, but a well-known game brand dominates the name. | 2026-10-04 11:42-11:44 UTC |
| Judge note: game owner and holdfast.com | USPTO record, web, direct fetch | conflict | Confirmed: Anvil Studios holds a live US registration in 9/41/42 for software and SaaS. Who runs holdfast.com is to run (fetch blocked). | 2026-10-04 11:43 UTC |
| Colombia (SIC) | sipi.sic.gov.co | to run | Proxy CONNECT 403. | to run (attempted 11:43 UTC) |

**Verdict: drop.** An identical, live, registered US mark for software in classes 9, 41 and 42, plus an exact-name audio app in the App Store's Music genre.

---

## Top 5 (ranked; blocking conflicts removed)

All five are **caution**. For every one of them, the EU, WIPO and Colombian (SIC) registers, the .app/.io/.fm/.co domains and the X, Instagram and TikTok handles are still **to run**.

### 1. Tunehold

- **Why:** It is the only finalist with nothing identical in any register, store or web check that ran, and with the exact .com, .net and GitHub name all free at check time. "Hold" means keep and own, it stays in the codename's Tune- family, and it is easy to spell and say in English and Spanish.
- **Main risk:** TUNEHOOD (US sn 99899715, pending, class 41 music-discovery website, filed 2026-06-23, in use in Tampa) is one letter away, in music. TUNE- is crowded (212 live marks in 9/42), so the mark is weak and rests on HOLD. The "hold music" reading is a positioning risk.
- **.com:** tunehold.com is not registered (Verisign 404 at 11:20 and ~16:59 UTC on 2026-10-04). tunehold.net, tuneholdapp.com and gettunehold.com are also free.
- **Founder must still run by hand:** EU (TMview/EUIPO) for TUNEHOLD and TUNEHOOD in 9/41/42; the WIPO Global Brand Database; Colombia SIC; tunehold.app/.fm/.io/.co at a registrar; the X, Instagram and TikTok handles. Also the judge's 5-listener "hold music" association test.

### 2. Carriel

- **Why:** The most distinctive name in the US and Canadian registers (no live CARRIEL mark, no app, no software brand). It also has the best fit and founder story: the Antioquian bag that carries what you value.
- **Main risk:** The home market. The SIC register is unchecked, and the "Carriel antioqueño" denomination of origin (Res. 72998/2025) could be raised under Decision 486 art. 135(j). After that come Carrier's famous mark one letter away (keyboards autocorrect to it), the English spelling after one hearing, and carriel.com, carriel.net and the GitHub login, all taken.
- **.com:** carriel.com has been registered since 2006 (NameSilo, Afternic nameservers, so probably for sale; unverified, price unknown). carrielapp.com, getcarriel.com and carrielmusic.com are free.
- **Founder must still run by hand:** Colombia SIC (any class), plus a Colombian IP lawyer's opinion on the denomination of origin (and the text of Res. 72998/2025); EU for CARRIEL, CARRIER and CAREL; WIPO; carriel.app/.io/.co/.fm; the X, Instagram and TikTok handles; the GitHub org "carriel"; the Afternic listing for carriel.com. Also the judge's say-and-spell and iOS/Gboard autocorrect tests.

### 3. Songfold

- **Why:** No SONGFOLD mark, app or brand was found, and the name is easy to spell and say. "Fold" is both a sheepfold that keeps things safe and a folder, which matches whole-folder uploads.
- **Main risk:** songfold.com is held by a third party on a 10-year term (2025 to 2035), which points to an active holder. Both SONG- and FOLD- are crowded, with SONGBOX (registered for music-file storage), SONGFLOW! (published) and SongFolder (unregistered, close in look and goods) nearby, so the mark is weak. The GitHub login is taken.
- **.com:** songfold.com is registered (Instra, 2025-05-28). songfold.net, songfoldapp.com, getsongfold.com, songfoldmusic.com and trysongfold.com are free.
- **Founder must still run by hand:** EU plus the UK IPO (FOLD Production Music); WIPO; Colombia SIC; songfold.app/.fm/.io/.co; the X, Instagram and TikTok handles; who holds songfold.com and what it serves. Also the judge's "fold = give up" reading test.

### 4. Kesto

- **Why:** Short, coined in English and easy in English and Spanish. There is no live KESTO mark in 9/41/42 in the US or Canada, because the old KESTO telecom marks are dead.
- **Main risk:** In Finnish it is the everyday word for "duration" and the track-length label in music apps. That is a descriptiveness risk for an EU mark, and the EU and Finland are unchecked. There are also three other exact-name apps in the App Store (none music), and almost every .com variant is taken.
- **.com:** kesto.com is registered (GoDaddy, 2004), as are kesto.net, kestoapp.com and getkesto.com (2026-07-15). kestomusic.com is free.
- **Founder must still run by hand:** EUIPO/TMview plus Finland's PRH; WIPO; Colombia SIC; kesto.app/.fm/.fi/.io; the X, Instagram and TikTok handles. Also the judge's Amharic/Tigrinya meaning check.

### 5. Porti

- **Why:** Clean in the US and Canadian registers. The meaning fits (carry, port), and Spanish and Portuguese speakers hear "por ti" ("for you").
- **Main risk:** It is the most-used name of the five. There are exact-name apps (the Portí fintech in five App Store storefronts and on Play, the PORTi delivery app in Spain, the Porti game), and Porti Music, LLC, a reggae label, uses the identical name in music (unregistered). porti.com and four .com variants are taken, and EU use is likely.
- **.com:** porti.com has been registered since 2000 (Ascio, Italian nameservers). tryporti.com is free.
- **Founder must still run by hand:** EU for PORTI and PORTÍ; WIPO; Colombia SIC, Spain OEPM and Brazil INPI (the Portí owner); Jamaica JIPO (Porti Music); porti.app/.io/.fm/.co; X, Instagram and TikTok (including @porti); GitHub portiapp and portimusic. Also the judge's English say-and-spell test.

## Recommendation: Tunehold

Tunehold has the fewest problems that cannot be fixed:

- Nothing identical turned up anywhere the checks could reach.
- The exact .com, .net and GitHub name were free at check time.
- Its one register issue, TUNEHOOD, is pending, in class 41 only, and differs in meaning (hood vs hold). The USPTO already lets many TUNE-X marks coexist.

Its cost is a weak, crowded stem and a "hold music" reading the brand voice has to steer away from. Carriel is the stronger mark and the better story, but its biggest unknowns are in the founder's home market (SIC and the denomination of origin), and those can only be settled by a Colombian lawyer. Choose Carriel instead only if that lawyer clears it and the founder accepts the English spelling and "Carrier" autocorrect cost.

Before money is spent on Tunehold:

1. Run the to-run rows above, starting with TMview (TUNEHOLD and TUNEHOOD) and Colombia's SIC.
2. Have a trademark lawyer run a full search in the US, the EU and Colombia, and weigh TUNEHOOD.
3. Run the 5-listener "hold music" test.

A .com that was free on 2026-10-04 can be taken at any time. Whether to hold tunehold.com for a registration fee while the lawyer works is the founder's call. Anything beyond that (filings, logo, marketing) should wait for the lawyer.

## Dropped

| name | blocking conflict |
|---|---|
| Earshelf | earshelf.com was registered 2026-09-28, and an identically named audio-playback subscription app (GitHub imwithoutlimits/earshelf, Free/Plus/Pro plans) started 2026-09-29. This reverses only if the founder owns either one. |
| Coffer | COFFR (US sn 99692561, filed 2026-03-10, live, classes 9/36/42 software) sounds identical and was filed earlier. Six or more exact-name live apps. coffer.com has been taken since 1997. A weak dictionary word. |
| Holdfast | HOLDFAST reg 8036173 (Anvil Studios, Malta) is a live US registration for software in classes 9/41/42. "Holdfast: Ambient Sounds" is an exact-name app in the App Store's Music genre. holdfast.com, .net and the app/get variants are all taken. |

*Screening checks run 2026-10-04, not legal clearance. A trademark lawyer should search before money is spent on any of these names.*
