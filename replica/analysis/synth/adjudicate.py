"""Synthesizer hand re-read of the rows that the fit (F) or market (M) lens put in a theme but the
evidence lens (E, core + 4-5 star scan) did not. Source dumps: disputed/<theme>.txt (from compare.py).

Rule applied: the evidence lens's definition of each theme is kept (it is the preferred lens).
A disputed row is ADDED only if it plainly meets that definition and E simply missed it.
Rows that belong elsewhere under E's definitions (e.g. free-tier forced shuffle -> free_tier_control,
Smart Shuffle -> playlist_injection, other apps' offline bugs -> excluded) are NOT added; the
reason class for each disputed theme is recorded in NOTES. Row ids below are 0-based (E/M convention);
the fit lens uses 1-based ids, so URLs are the join key.
"""

ADD = {
    # 4-star GP review: "just hated that smart shuffle" (Smart Shuffle is in E's injection definition)
    # 4-star AS review: autoplay continued after the playlist ended and played an audiobook (autoplay is in E's definition)
    'playlist_injection': [
        'https://play.google.com/store/apps/details?id=com.spotify.music&hl=en_US&gl=US#review-2',          # idx0 1075
        'https://itunes.apple.com/ie/rss/customerreviews/page=4/id=324684580/sortby=mostrecent/xml#review-14429893822',  # idx0 776
    ],
    # 5-star reviews naming a concrete free-tier control limit (skips / daily limit)
    'free_tier_control': [
        'https://itunes.apple.com/ie/rss/customerreviews/page=1/id=324684580/sortby=mostrecent/json#review-14612364033',  # idx0 354 "way more skipss"
        'https://play.google.com/store/apps/details?id=com.spotify.music&hl=en_IN&gl=IN#review-7',          # idx0 712 "day limit"
    ],
}

NOTES = {
    'shuffle_not_random': 'E 25 (17 core + 8 4-5*), F 52, M 31. Re-read the 27 unique disputed rows: 15 are free-tier forced shuffle / no play-in-order (E files them under free_tier_control), 4 are Smart Shuffle or "album shuffle plays other artists" (E: playlist_injection), 4 are feature requests (shuffle whole library, shuffle the queue, album shuffle, least-played first), 1 is duplicates causing repeats (E excludes by rule), 2 are ambiguous ("hate the shuffle") or radio, 1 borderline (HN "true(r) random playlist", idx0 1069) not added. 0 added.',
    'playlist_injection': 'E 31 (25 core + 6 4-5*), F 34, M 47. M ALGO also codes radio/daily-mix drift and AI DJ (E: recs_bad); F adds free-tier "playing a similar song for you" substitutions (E: free_tier_control). 2 within-definition misses added (Smart Shuffle 4*, autoplay-after-playlist 4*). Final 33.',
    'offline_broken': 'E 27 (26 core + 1 4-5*), F 41, M 26. F OFF also codes the free-tier download paywall, other apps\' offline failures (YouTube Music, Amazon, Apple), Local Files sync workflow and a hostage-after-cancel case. 2 borderline (idx0 539 "cannot use it in WiFi", idx0 669 skipping on downloaded files) not added. 0 added.',
    'playback_reliability': 'E 28 core (4-5* folded into E high bugs_reliability 22), F 41. F INT also codes crashes while playing (E: bugs_crashes) and 4-5* reviews. 0 added.',
    'queue_ux': 'E 16 (13 core + 3 4-5*), F 22. F Q also codes the free-tier queue paywall (E: ftc_queue) and shuffle-queue repeats (E: shuffle). 0 added.',
    'library_tools': 'E 18 (8 core + 10 4-5*), F 31, M 6. F ORG also codes add-to-playlist UI flows (E: ui_navigation) and listening history (E: separate theme, 9). M META is narrower (tags/duplicates). 0 added.',
    'review_prompts': 'E 12 (11 core + 1 4-5*), F NAG 28. F NAG also codes upsell reminders, promo pop-ups and notifications (E: clutter_promos / ads_while_paying). No disputed row mentions a rating prompt. 0 added.',
    'free_tier_control': 'E 114 (88 core + 26 4-5*), F 117, M 154. M PAYWALL also codes generic "need premium for everything" 4-5* reviews (E keeps generic complaints in paywall_generic, core only) and some ad/price-only rows. 2 within-definition 4-5* misses added (skip cap, day limit); 2 borderline (idx0 743, 887) not added. Final 116.',
    'own_files': 'E core union (upload | own/export | self-host effort) 67, +local files +4-5* = 71 distinct; F OWN_FILES 70; M collectors 60. E own_music_upload 34 is broader than F UP 21 / M LOCKER 22 because E also counts "music not on Spotify" and Local Files workflow rows; F OWN 49 is broader than E ownership_export 30 because F OWN also codes pro-ownership statements and self-hosting stacks. Definitional; evidence numbers kept.',
    'switching': 'E did not measure switching. F 105 vs M 112 (both all-ratings, hand-checked); union and intersection computed in recount.py; both sides HN-heavy.',
    'ads': 'E 208 (131 core + 77 4-5*), M 207 (ADS|ADSPAID). Same size; 10 M-only / 11 E-only rows are boundary calls ("adds" as a verb, ads on other apps). 0 added.',
    'price': 'E 82 (62 core + 20 4-5*, increases included), M 101. M PRICE also codes "greed" and currency-as-leverage rows that E removed as false positives after reading every match. 0 added.',
    'clutter_promos': 'E 49 (46 core + 3 4-5*), F BLOAT 39, M CLUTTER|PROMO 43. E is the broadest (includes promo pop-ups and home-feed control). 0 added.',
}
