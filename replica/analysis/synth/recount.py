"""Synthesizer step 2: re-derive every number the draft cites, from reviews.csv and the lens sidecars.

Inputs (read-only):
  /home/user/Spotify-clon/replica/reviews.csv
  ../evidence-themes.json            (evidence lens per-theme URL lists; preferred numbers)
  ../fit/counts.json, ../market/counts.json, ../market/segments.json  (for disagreement checks)
  adjudicate.py                      (synthesizer's hand re-read of disputed rows)
Output: recount.json (+ printed summary). Every theme entry carries its URL list.
Run: python3 compare.py && python3 recount.py
"""
import csv, json, os, re, collections
from adjudicate import ADD, NOTES

HERE = os.path.dirname(os.path.abspath(__file__))
A = os.path.dirname(HERE)
rows = list(csv.DictReader(open('/home/user/Spotify-clon/replica/reviews.csv', encoding='utf-8')))
by = {r['url']: r for r in rows}
E = json.load(open(os.path.join(A, 'evidence-themes.json')))
F = json.load(open(os.path.join(A, 'fit', 'counts.json')))
Mc = json.load(open(os.path.join(A, 'market', 'counts.json')))
Ms = json.load(open(os.path.join(A, 'market', 'segments.json')))
out = {}

def src(urls):
    c = collections.Counter(by[u]['source'] for u in urls)
    return {k: c[k] for k in ('app-store', 'google-play', 'hacker-news') if c[k]}

# ---------- 1. sample ----------
s = {'rows': len(rows), 'by_source': src([r['url'] for r in rows])}
for k in ('app-store', 'google-play', 'hacker-news'):
    d = sorted(r['date'] for r in rows if r['source'] == k)
    s[k + '_dates'] = (d[0], d[-1])
s['ratings'] = {f"{a}:{b or '-'}": n for (a, b), n in collections.Counter((r['source'], r['rating']) for r in rows).items()}
pages = set()
cc = collections.Counter()
for r in rows:
    if r['source'] == 'app-store':
        m = re.search(r'itunes\.apple\.com/(\w+)/rss/customerreviews/page=(\d+)/', r['url'])
        pages.add((m.group(1), int(m.group(2))))
        cc[m.group(1)] += 1
s['appstore_pages_captured'] = len(pages)
s['appstore_pages_possible'] = 6 * 10
s['appstore_rows_by_storefront'] = dict(cc)
s['appstore_sep_oct_2026'] = sum(1 for r in rows if r['source'] == 'app-store' and r['date'] >= '2026-09-01')
core = [r for r in rows if r['source'] == 'hacker-news' or (r['rating'] and int(r['rating']) <= 3)]
high = [r for r in rows if r['rating'] and int(r['rating']) >= 4]
s['core_n'] = len(core); s['core_by_source'] = src([r['url'] for r in core])
s['high_n'] = len(high); s['high_by_source'] = src([r['url'] for r in high])
out['sample'] = s

# ---------- 2. themes (evidence lens numbers + synthesizer re-read additions) ----------
def theme(name, high_name=None):
    c = set(E['core'][name]['urls']) if name in E['core'] else set()
    hn = high_name or name
    h = set(E['high'][hn]['urls']) if hn in E['high'] else set()
    add = set(ADD.get(name, []))
    allu = c | h
    final = allu | add
    dates = sorted(by[u]['date'] for u in final)
    return {'core_n': len(c), 'core_src': src(c), 'high_n': len(h), 'high_scanned': hn in E['high'],
            'high_src': src(h), 'evidence_total': len(allu), 'evidence_total_src': src(allu),
            'reread_added': sorted(add - allu), 'final_n': len(final), 'final_src': src(final),
            'final_n_sources': len(src(final)), 'thin': len(final) < 3 or len(src(final)) < 2,
            'date_min': dates[0] if dates else None, 'date_max': dates[-1] if dates else None,
            'urls': sorted(final), 'core_urls': sorted(c)}

THEMES = ['ads', 'ads_while_paying', 'free_tier_control', 'paywall_generic', 'price', 'price_increase',
          'bugs_crashes', 'clutter_promos', 'ui_navigation', 'slow', 'playback_reliability', 'recs_bad',
          'offline_broken', 'login_account', 'playlist_injection', 'artist_pay_politics', 'catalogue_removals',
          'billing_support', 'shuffle_not_random', 'app_icon', 'devices_connect', 'devices_paywall', 'ai_music',
          'queue_ux', 'review_prompts', 'audiobook_hours', 'ai_features', 'car', 'library_data_loss',
          'lockscreen_background', 'location_travel', 'kids_content', 'ipad_tablet', 'podcast_mgmt',
          'own_music_upload', 'local_files_clunky', 'ownership_export', 'export_transfer', 'library_tools',
          'listening_history', 'audio_quality', 'lyrics', 'discovery_missed', 'selfhost_effort', 'selfhost_movers']
out['themes'] = {t: theme(t) for t in THEMES}
out['themes']['high_only_bugs_reliability'] = {'high_n': E['high']['bugs_reliability']['n'], 'high_src': src(E['high']['bugs_reliability']['urls'])}
out['themes']['high_only_praise_discovery'] = {'high_n': E['high']['praise_discovery']['n'], 'high_src': src(E['high']['praise_discovery']['urls'])}
out['themes']['high_only_praise_background_play'] = {'high_n': E['high']['praise_background_play']['n'], 'high_src': src(E['high']['praise_background_play']['urls'])}

# ---------- 3. date splits (core lists of the evidence lens) ----------
def count_dates(name, pred):
    us = E['core'][name]['urls']
    return sum(1 for u in us if pred(by[u]['date'])), len(us)
ds = {}
ds['login_on_2026-09-29'] = count_dates('login_account', lambda d: d == '2026-09-29')
ds['ftc_after_2025-09-15_pickplay'] = count_dates('free_tier_control', lambda d: d > '2025-09-15')
ds['ftc_in_2026'] = count_dates('free_tier_control', lambda d: d >= '2026-01-01')
ds['shuffle_after_2025-11-13_fewer_repeats'] = count_dates('shuffle_not_random', lambda d: d > '2025-11-13')
ds['offline_after_2026-05-28_bg_downloads'] = count_dates('offline_broken', lambda d: d > '2026-05-28')
ds['offline_in_2026'] = count_dates('offline_broken', lambda d: d >= '2026-01-01')
ds['injection_after_2026-05-13_smartshuffle_article'] = count_dates('playlist_injection', lambda d: d > '2026-05-13')
ds['audio_quality_before_2025-09-10_lossless'] = count_dates('audio_quality', lambda d: d < '2025-09-10')
ds['app_icon_2026-05_to_06'] = count_dates('app_icon', lambda d: '2026-05-01' <= d <= '2026-06-30')
ds['ipad_after_2026-04-16_tablet'] = count_dates('ipad_tablet', lambda d: d > '2026-04-16')
ds['queue_after_2026-05-28_multiselect'] = count_dates('queue_ux', lambda d: d > '2026-05-28')
ds['catalogue_removals_hn'] = (src(E['core']['catalogue_removals']['urls']).get('hacker-news', 0), E['core']['catalogue_removals']['n'])
out['date_splits'] = ds

# ---------- 4. aggregates ----------
low_store = [r['url'] for r in rows if r['source'] != 'hacker-news' and r['rating'] and int(r['rating']) <= 3]
ft = set(E['core']['ads']['urls']) | set(E['core']['free_tier_control']['urls']) | set(E['core']['paywall_generic']['urls'])
out['free_tier_share_low_store'] = (len(ft & set(low_store)), len(low_store))
own_core = set(E['core']['own_music_upload']['urls']) | set(E['core']['ownership_export']['urls']) | set(E['core']['selfhost_effort']['urls'])
out['own_files_core_union_upload_own_effort'] = {'n': len(own_core), 'src': src(own_core)}
own_core2 = own_core | set(E['core']['local_files_clunky']['urls'])
own_all = own_core2 | set(E['high']['own_music_upload']['urls'])
out['own_files_all_incl_localfiles_and_45star'] = {'n': len(own_all), 'src': src(own_all), 'urls': sorted(own_all)}
fs = set(F['switch']['urls']); ms = {x['url'] for x in Mc['SWITCH']}
out['switching'] = {'fit_n': len(fs), 'fit_src': src(fs), 'market_n': len(ms), 'market_src': src(ms),
                    'union_n': len(fs | ms), 'union_src': src(fs | ms), 'intersection_n': len(fs & ms)}
fo = set(F['switch']['upload_or_own_files_reason']['urls'])
out['switching']['fit_upload_or_own_reason'] = {'n': len(fo), 'src': src(fo)}
# switchers that also appear in the evidence own-files union
out['switching']['union_and_ownfiles'] = len((fs | ms) & own_all)
out['notes'] = NOTES
json.dump(out, open(os.path.join(HERE, 'recount.json'), 'w'), indent=1)

# ---------- print ----------
print('SAMPLE', json.dumps({k: v for k, v in s.items() if k != 'ratings'}))
print('\ntheme | core(src) | 4-5*(src) | evidence total | re-read +k | final n | sources | thin | dates')
for t in THEMES:
    d = out['themes'][t]
    print(f"{t} | {d['core_n']} {d['core_src']} | {d['high_n'] if d['high_scanned'] else 'n/s'} {d['high_src']} | {d['evidence_total']} | +{len(d['reread_added'])} | {d['final_n']} | {d['final_src']} | {d['thin']} | {d['date_min']}..{d['date_max']}")
for k in ('high_only_bugs_reliability', 'high_only_praise_discovery', 'high_only_praise_background_play'):
    print(k, out['themes'][k])
print('\nDATE SPLITS'); [print(' ', k, v) for k, v in ds.items()]
print('free-tier-driven share of low-rated store reviews:', out['free_tier_share_low_store'])
print('own files core (upload|own|effort):', out['own_files_core_union_upload_own_effort'])
print('own files all (+local files, +4-5*):', {k: v for k, v in out['own_files_all_incl_localfiles_and_45star'].items() if k != 'urls'})
print('switching:', out['switching'])
