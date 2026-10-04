"""verify-counts: sample-section checks, sub-splits, unions and date splits re-derived from reviews.csv + labels.txt."""
import csv, re, json, collections, os
from vcount import rows, L, ids, src, is_core
out = {}
# ---- sample section
S = {}
S['by_source'] = dict(collections.Counter(r['source'] for r in rows))
for s in ('app-store', 'google-play', 'hacker-news'):
    d = sorted(r['date'] for r in rows if r['source'] == s); S[s + '_dates'] = (d[0], d[-1])
S['ratings'] = {f"{k[0]}:{k[1] or '-'}": v for k, v in sorted(collections.Counter((r['source'], r['rating']) for r in rows).items())}
pages = set(); sf = collections.Counter(); pg_sf = collections.Counter()
for r in rows:
    if r['source'] == 'app-store':
        m = re.search(r'itunes\.apple\.com/(\w+)/rss/customerreviews/page=(\d+)/', r['url'])
        sf[m.group(1)] += 1; pages.add((m.group(1), int(m.group(2))))
for c, p in pages: pg_sf[c] += 1
S['appstore_storefront_rows'] = dict(sf); S['appstore_pages'] = len(pages); S['appstore_pages_by_sf'] = dict(pg_sf)
S['appstore_sep_oct'] = sum(1 for r in rows if r['source'] == 'app-store' and r['date'] >= '2026-09-01')
core = [i for i, r in enumerate(rows) if is_core(r)]
S['core'] = len(core); S['core_src'] = src(core)
S['high'] = len(rows) - len(core)
out['sample'] = S
# ---- ftc sub-splits (core)
out['ftc_core_subsplit'] = {k: len(ids(k, 'core')) for k in ('ftc_pick', 'ftc_skip', 'ftc_order', 'ftc_seek', 'ftc_repeat', 'ftc_queue')}
fc = ids('ftc', 'core')
out['ftc_core_after_2025-09-15'] = [sum(1 for i in fc if rows[i]['date'] > '2025-09-15'), len(fc)]
# ---- ads lexical check: core ads reviews that never write ad/ads/advert/commercial
ac = ids('ads', 'core')
lex = re.compile(r"\b(ads?|ad's|advert\w*|commercials?|advertis\w*)\b", re.I)
nolex = [i for i in ac if not lex.search(rows[i]['text'])]
out['ads_core_without_ad_word'] = [len(nolex), len(ac), [rows[i]['text'][:60] for i in nolex]]
# ---- share of low-rated store reviews in ads / ftc / paywall
low_store = [i for i, r in enumerate(rows) if r['source'] != 'hacker-news' and int(r['rating']) <= 3]
fr = [i for i in low_store if L[i] & {'ads', 'ftc', 'paywall'}]
out['low_store_ads_ftc_paywall'] = [len(fr), len(low_store), round(100 * len(fr) / len(low_store), 1)]
fr2 = [i for i in low_store if L[i] & {'ftc', 'paywall'}]
out['low_store_ftc_paywall_only'] = [len(fr2), len(low_store)]
# ---- price incl. price increases (draft treats increases as a subset of price)
p = sorted(set(ids('price')) | set(ids('price_inc')))
out['price_union_inc'] = {'n': len(p), 'core': sum(1 for i in p if is_core(rows[i])), 'src': src(p)}
# ---- upload as the evidence lens defined it (upload incl. Local Files and not-on-streaming rows)
u = sorted(set(ids('upload')) | set(ids('localfiles')) | set(ids('notonstreaming')))
out['upload_union'] = {'n': len(u), 'core': sum(1 for i in u if is_core(rows[i])), 'src': src(u), 'core_src': src([i for i in u if is_core(rows[i])])}
# ---- own incl. export
o = sorted(set(ids('own')) | set(ids('export')))
out['own_union_export'] = {'n': len(o), 'src': src(o)}
# ---- U1 own-files group: upload ∪ own ∪ self-host effort (core)
eff = set(ids('selfhost_effort')) | set(ids('selfhost_pref'))
g = sorted((set(u) | set(o) | eff) & set(core))
out['own_files_group_core'] = {'n': len(g), 'src': src(g)}
g2 = sorted((set(ids('upload', 'core')) | set(ids('own', 'core')) | eff))
out['own_files_group_narrow_core'] = {'n': len(g2), 'src': src(g2), 'note': 'upload+own+effort codes only, no localfiles/notonstreaming/export'}
st = set(ids('selfhost_stack'))
out['selfhost'] = {'effort_incl_pref': len(eff), 'stack': len(st), 'overlap': len(eff & st), 'distinct': len(eff | st)}
# ---- date splits
def split(code, scope, pred):
    I = ids(code, scope); return [sum(1 for i in I if pred(rows[i]['date'])), len(I)]
out['date_splits'] = {
 'login_core_on_2026-09-29': split('login', 'core', lambda d: d == '2026-09-29'),
 'shuffle_core_after_2025-11-13': split('shuffle', 'core', lambda d: d > '2025-11-13'),
 'offline_core_after_2026-05-28': split('offline', 'core', lambda d: d > '2026-05-28'),
 'inject_core_after_2026-05-13': split('inject', 'core', lambda d: d > '2026-05-13'),
 'lossless_core_before_2025-09-10': split('lossless', 'core', lambda d: d < '2025-09-10'),
 'icon_core_2026-05_to_06': split('icon', 'core', lambda d: '2026-05-01' <= d <= '2026-06-30'),
 'ipad_core_after_2026-04-16': split('ipad', 'core', lambda d: d > '2026-04-16'),
 'queue_core_after_2026-05-28': split('queue', 'core', lambda d: d > '2026-05-28'),
}
off = ids('offline', 'core')
out['offline_core_store_2025_2026'] = [sum(1 for i in off if rows[i]['source'] != 'hacker-news' and rows[i]['date'] >= '2025'), sum(1 for i in off if rows[i]['source'] != 'hacker-news')]
out['offline_core_hn_2023_2024'] = [sum(1 for i in off if rows[i]['source'] == 'hacker-news' and rows[i]['date'] < '2025'), sum(1 for i in off if rows[i]['source'] == 'hacker-news')]
out['dupes_note'] = 'rows 713, 891, 1107 (google-play IN listing) are near-identical texts (Jaccard 0.85-0.87) dated 2025-08-29, 2026-07-09, 2026-09-15'
# ---- music-only candidates by keyword (hide/disable/turn off/remove + podcast/audiobook/video), then read
pat = re.compile(r"(hide|disable|turn (it |them )?off|remove|get rid|deactivate|block|opt out|no way to (turn|stop|block)).{0,60}(podcast|audio ?book|video)|(podcast|audio ?book|video).{0,60}(hide|disable|turn (it |them )?off|remove|get rid|deactivate|block|opt out)", re.I)
out['music_only_candidates'] = [(i, rows[i]['source'], rows[i]['rating'], rows[i]['text'][:200]) for i, r in enumerate(rows) if pat.search(r['text'])]
json.dump(out, open('verify-extra.json', 'w'), indent=1, default=str)
for k, v in out.items():
    if k == 'music_only_candidates':
        print(k, len(v));
        for c in v: print('   ', c)
    else: print(k, v)
