# Deferred until a public launch is decided

Decision (2026-10-04, by the founder): for now Tunehold is **for personal use** by the founder and a few friends. Everything about selling it (payments, pricing, legal, store listings, market validation) is **deferred**. It gets picked up only if and when the founder decides to launch publicly. Until then these items are out of scope for every phase and every agent. Don't build them, don't block on them, don't put them in specs.

What changes now:
- **No payments or plans.** No Stripe, no in-app purchases, no checkout, no plan tiers or entitlements. Every account gets the same features. A simple per-user storage limit set by the admin (the founder) replaces "storage quota per plan".
- **No market-validation gate.** The landing-page test and its pass/fail thresholds (`fixes.md` section 6, HARD GATE) don't apply. The landing page is a plain presentation page: no prices, no waitlist, no deposit.
- **Invite-only accounts.** The founder creates or invites accounts. There is no public sign-up.
- **No legal workstream.** No DMCA agent, takedown or report flow, launch-country regimes, terms of service or privacy policy work for now. Files are private to the user who uploaded them, and nothing is publicly shared, which keeps exposure minimal while it's private.
- **No store listings.** No App Store or Google Play listing, store billing or `listing.py` run. Mobile builds for the founder and friends go through development builds or internal testing (Expo, TestFlight internal, Play internal testing).

Kept, because they're product or engineering decisions, not legal or payment ones:
- Upload your own files; keep the stored copy bit for bit; no cross-user deduplication (per-user copies are also simpler).
- Web + iOS + Android from the start (founder's choice, 2026-10-04).
- The fix plan's product items: F2 (playlists play only their own tracks), F3 (quiet, music-only app), F4 (shuffle for large collections), F5 (offline downloads), F6 (bulk folder upload), F7 (export on demand, the export part only), F8 (personal play counts, smart playlists).
- Cost awareness: storage and egress still cost money even for personal use (`fixes.md` section 7, Costs). /replica-architect picks cheap managed services.
- Brand (`brand.md`), tokens and voice. Ignore the strings about plans, quotas per plan or cancelling.

## The deferred list (where each item is described)

| item | where it is described |
| --- | --- |
| Pricing model, free quota, storage tiers, unit economics in dollars | `fixes.md` section 7 (For /replica-launch, Costs) |
| Landing-page market test (gate spec, paid-intent metric, traffic, thresholds, stop outcome) | `fixes.md` section 6 (HARD GATE) |
| Store billing (Apple IAP, Google Play Billing, web checkout route) | `fixes.md` section 7 (Store billing covers every paid plan) |
| Plan rules: downgrade/cancel over-quota rule, inactivity rule, device caps per plan | `fixes.md` F5, F7; `features.csv` notes on plans, quota and downloads |
| Notice and takedown (DMCA agent, counter-notice, repeat-infringer policy, launch-country regimes, report form S26) | `fixes.md` section 7 (Legal), F11 in `recon.md` |
| Sharing beyond the user's own account (tracklist-only links, public profiles, collaborative playlists) | `fixes.md` section 7 (sharing), `features.csv` social rows |
| Terms of service, privacy policy, data export obligations | `fixes.md` section 7 |
| App Store / Google Play listings, screenshots, privacy labels | `.claude/skills/replica-launch/SKILL.md` step 3 |
| Trademark clearance by a lawyer (US, EU, Colombia), tunehold.com registration, renaming the GitHub repo before going public | `brand.md` |
| Launch plan (waitlist, Product Hunt, first users) | `.claude/skills/replica-launch/SKILL.md` step 4 |

When the founder decides to launch, start from this table and from `fixes.md` sections 6 and 7.
