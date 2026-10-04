"""verify-counts step 3: corrected counts after re-reading every disagreement row (vdiff.py output).
corrected(theme) = verifier labels  + evidence-lens rows ACCEPTED on re-read  - verifier rows REJECTED on re-read.
Every accept/reject below was decided by reading the full text; reason in the comment. Row ids are 0-based reviews.csv rows."""
import json, collections
from vcount import rows, ids, src, is_core
ADJ = {
 # code: (accept_from_evidence, reject_from_mine, also_union_codes)
 'ads': ([528, 932, 935, 1079, 1098, 1099, 1131, 1163, 708, 786],   # paid users' ads / sponsored = ads; mild 5* "only downside is the ads"
         [888, 354], []),                                               # 888 no ad mention; 354 "added" ambiguous
 'ftc': ([680, 808, 966], [], []),                                       # free tier plays random songs instead of chosen ones (borderline accept)
          # rejected EV-only: 122 generic limits (paywall), 543 recommended-song injection, 1084 generic "terrible free version" (no control named)
 'bugs': ([5, 197, 253, 350, 381, 401, 421, 435, 682, 1010, 1064, 1076], [], []),  # all real malfunction reports
 'price': ([533, 793, 211, 93, 700], [], ['price_inc']),                 # rejected: 226 promo code, 270, 657, 708, 853 (no "too expensive" complaint)
 'clutter': ([1082, 1131], [], []),                                      # rejected: 159/713/891/1107 Premium-upsell reminders (713/891/1107 = one duplicated text), 203 jam invite, 397 "bloat"=speed
 'inject': ([244, 819, 847], [], []),                                    # rejected: 1136 editorial-playlist personalisation, 1189 shuffle-button UX, 1209 autoplay/radio, 1215 algorithmic playlist push
 'queue': ([177, 718, 833, 1101], [], []),                               # all queue complaints/requests (draft's 16 stands)
 'libtools': ([1144], [], []),                                           # rejected: 151, 625, 726, 910 = add-to-playlist / playlist-editing requests, not the named library tools
 'lossless': ([1199], [], []),                                           # rejected: 365, 1162 = equaliser (EQ) requests, not lossless
 'upload': ([1152], [], ['localfiles', 'notonstreaming']),               # rejected: 983, 1053 catalogue wishes (YouTube/SoundCloud songs), 1027 ambiguous "can't upload songs" next to a load failure
 'own': ([524, 1129, 1139, 1162, 1170, 1195], [], ['export']),           # transfer/export rows (draft folds export into own)
 'selfhost_effort': ([1086, 1089, 1104, 1144, 1170, 1183, 1186], [], []),# broad reading: friction of hosting/collecting/syncing own library. rejected: 1091 (cost of buying music), 1206 (a company's storage cost)
 'discovery_missed': ([1137, 1208], [], []),                             # rejected 10: about streaming discovery in general (732, 1073, 1078, 1080, 1089, 1166, 1193, 1199, 1220, 1226), not "missed after moving to owned files"
 'praise_background': ([12, 318, 1024], [], []),                         # verifier recall misses; evidence lens right
 'car': ([], [], []),                                                    # rejected: 1010 (fails with or without CarPlay), 1146 (playlist switch while driving)
 'lockscreen': ([], [], []),                                             # rejected: 577 feature request (repeat button on lock screen), not "broken"
 'icon': ([], [], []),                                                   # rejected: 1102 HN 2025 remark on a logo hue change inside a UI-churn complaint (different event)
 'replaced': ([], [], ['conversion']),                                   # draft U3 includes forced-conversion statements (1206, 1212)
 'offline_other': ([1220], [], []),                                      # Apple Music offline "nerfed"
 'hostage': ([122], [], []),                                             # limits imposed after a missed payment
}
out = {}
for code, (acc, rej, uni) in ADJ.items():
    s = set(ids(code))
    for u in uni: s |= set(ids(u))
    s = (s | set(acc)) - set(rej)
    c = sorted(i for i in s if is_core(rows[i])); h = sorted(i for i in s if not is_core(rows[i]))
    out[code] = {'n': len(s), 'core': len(c), 'high': len(h), 'src': src(s), 'core_src': src(c), 'accepted_from_evidence': acc, 'rejected_from_verifier': rej,
                 'thin': len(s) < 3 or len(src(s)) < 2, 'urls': [rows[i]['url'] for i in sorted(s)]}
    print(f"{code:18} n={len(s):4} core={len(c):4} high={len(h):3} src={src(s)} thin={out[code]['thin']}")
# derived date splits on corrected sets
def after(code, d, core=True):
    I = [rows[i]['url'] for i in []]
inj = [i for i in set(ids('inject')) | {244, 819, 847} if is_core(rows[i])]
out['inject_core_after_2026-05-13'] = [sum(1 for i in inj if rows[i]['date'] > '2026-05-13'), len(inj)]
ll = [i for i in set(ids('lossless')) | {1199} if is_core(rows[i])]
out['lossless_core_before_2025-09-10'] = [sum(1 for i in ll if rows[i]['date'] < '2025-09-10'), len(ll)]
hb = sorted(set(ids('bugs', 'high')) | set(ids('playback', 'high')) | set(ids('slow', 'high')))
out['high_bugs_reliability_bucket'] = len(hb)
print({k: out[k] for k in ('inject_core_after_2026-05-13', 'lossless_core_before_2025-09-10', 'high_bugs_reliability_bucket')})
json.dump(out, open('verify-corrected.json', 'w'), indent=1)
