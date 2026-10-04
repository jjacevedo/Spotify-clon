"""Synthesizer step 1: compare the three lenses theme by theme, keyed by review URL.

Lenses:
  E = evidence lens  (../evidence-themes.json; core = rating<=3 or HN, high = 4-5 stars, 0-based ids)
  F = fit lens       (../fit/counts.json; all ratings, 1-based ids -> we use urls)
  M = market lens    (../market/counts.json codes and ../market/segments.json; all ratings, 0-based idx)
For each mapped theme we report |E_core|, |E_high|, |E_all|=core|high, |F|, |M|, overlaps,
and dump the rows that F or M have but E_all does not (to be read by hand in adjudicate.py).
Run: python3 compare.py -> compare.json, compare.txt, disputed/<theme>.txt
"""
import csv, json, os, collections
HERE = os.path.dirname(os.path.abspath(__file__))
A = os.path.dirname(HERE)
rows = list(csv.DictReader(open('/home/user/Spotify-clon/replica/reviews.csv', encoding='utf-8')))
by_url = {r['url']: r for r in rows}
idx_of = {r['url']: i for i, r in enumerate(rows)}

E = json.load(open(os.path.join(A, 'evidence-themes.json')))
F = json.load(open(os.path.join(A, 'fit', 'counts.json')))['themes']
Mc = json.load(open(os.path.join(A, 'market', 'counts.json')))
Ms = json.load(open(os.path.join(A, 'market', 'segments.json')))

def e(theme, part):
    d = E[part].get(theme)
    return set(d['urls']) if d else set()
def f(*codes):
    s = set()
    for c in codes:
        s |= set(F[c]['urls'])
    return s
def m(*codes):
    s = set()
    for c in codes:
        s |= {x['url'] for x in Mc.get(c, [])}
    return s

# theme -> (evidence theme names, fit codes, market codes)
MAP = {
  'ads':                 (['ads'], [], ['ADS', 'ADSPAID']),
  'ads_while_paying':    (['ads_while_paying'], [], ['ADSPAID']),
  'free_tier_control':   (['free_tier_control'], ['CTRL'], ['PAYWALL']),
  'shuffle_not_random':  (['shuffle_not_random'], ['SH'], ['SHUFFLE']),
  'playlist_injection':  (['playlist_injection'], ['INJ'], ['ALGO']),
  'offline_broken':      (['offline_broken'], ['OFF'], ['OFFLINE']),
  'playback_reliability':(['playback_reliability'], ['INT'], []),
  'clutter_promos':      (['clutter_promos'], ['BLOAT'], ['CLUTTER', 'PROMO']),
  'nag_group':           (['review_prompts', 'ads_while_paying'], ['NAG'], ['PROMO']),
  'review_prompts':      (['review_prompts'], ['NAG'], []),
  'catalogue_removals':  (['catalogue_removals'], ['LOST'], ['REMOVED']),
  'queue_ux':            (['queue_ux'], ['Q'], []),
  'library_tools':       (['library_tools'], ['ORG'], ['META']),
  'listening_history':   (['listening_history'], [], ['STATS']),
  'own_music_upload':    (['own_music_upload'], ['UP'], ['LOCKER']),
  'local_files_clunky':  (['local_files_clunky'], ['LF'], ['LOCALPAIN']),
  'ownership_export':    (['ownership_export'], ['EXP', 'OWN'], ['OWNERSHIP', 'HOSTAGE', 'LOCKIN']),
  'own_files_group':     (['own_music_upload', 'ownership_export', 'local_files_clunky'], ['LF', 'UP', 'OWN'], ['OWN', 'LOCKER', 'LOCALPAIN', 'SELFHOST']),
  'ownership_hostage':   (['ownership_export'], ['OWN'], ['OWNERSHIP', 'HOSTAGE']),
  'export_transfer':     (['export_transfer'], ['EXP'], ['LOCKIN']),
  'price':               (['price', 'price_increase'], [], ['PRICE', 'PRICERISE']),
  'price_increase':      (['price_increase'], [], ['PRICERISE']),
  'artist_pay_politics': (['artist_pay_politics'], [], ['POLITICS']),
  'ai_music':            (['ai_music'], [], ['AISLOP']),
  'lockscreen_car':      (['lockscreen_background', 'car'], ['BG'], []),
  'library_data_loss':   (['library_data_loss'], ['LOSS'], []),
  'devices_paywall':     (['devices_paywall'], ['CAST'], []),
  'audio_quality':       (['audio_quality'], [], ['QUALITY']),
  'discovery_missed':    (['discovery_missed'], [], ['DISCOVERY']),
  'selfhost_effort':     (['selfhost_effort'], [], ['EFFORT']),
  'selfhost_movers':     (['selfhost_movers'], [], ['SELFHOST']),
  'kids_content':        (['kids_content'], [], ['KIDSAFE']),
}

def srcs(urls):
    c = collections.Counter(by_url[u]['source'] for u in urls)
    return dict(c)

out = {}
os.makedirs(os.path.join(HERE, 'disputed'), exist_ok=True)
lines = ['theme | E_core | E_high | E_all | F | M | F&E_all | M&E_all | F-only(not E_all) | M-only(not E_all) | E_all not in F | E_all not in M']
for t, (et, fc, mc) in MAP.items():
    ec = set().union(*[e(x, 'core') for x in et])
    eh = set().union(*[e(x, 'high') for x in et])
    ea = ec | eh
    fs = f(*fc) if fc else None
    ms = m(*mc) if mc else None
    rec = {'E_core': sorted(ec), 'E_high': sorted(eh), 'E_all_n': len(ea),
           'E_core_src': srcs(ec), 'E_all_src': srcs(ea),
           'E_high_scanned': any(x in E['high'] for x in et)}
    fo = sorted((fs - ea)) if fs is not None else []
    mo = sorted((ms - ea)) if ms is not None else []
    rec.update({'F_n': len(fs) if fs is not None else None, 'M_n': len(ms) if ms is not None else None,
                'F_src': srcs(fs) if fs else None, 'M_src': srcs(ms) if ms else None,
                'F_only': fo, 'M_only': mo,
                'E_not_F': sorted(ea - fs) if fs is not None else [],
                'E_not_M': sorted(ea - ms) if ms is not None else []})
    out[t] = rec
    lines.append(f"{t} | {len(ec)} | {len(eh)}{'' if rec['E_high_scanned'] else '(not scanned)'} | {len(ea)} | "
                 f"{rec['F_n']} | {rec['M_n']} | {len(fs & ea) if fs is not None else '-'} | {len(ms & ea) if ms is not None else '-'} | "
                 f"{len(fo)} | {len(mo)} | {len(rec['E_not_F'])} | {len(rec['E_not_M'])}")
    # dump disputed rows (in F or M but not E_all), with which lens and E themes the row has
    dis = sorted(set(fo) | set(mo), key=lambda u: idx_of[u])
    if dis:
        with open(os.path.join(HERE, 'disputed', f'{t}.txt'), 'w') as fh:
            for u in dis:
                r = by_url[u]
                ethemes = [k for k, v in E['core'].items() if u in v['urls']] + ['high:' + k for k, v in E['high'].items() if u in v['urls']]
                who = ('F' if u in fo else '') + ('M' if u in mo else '')
                fh.write(f"=== idx0={idx_of[u]} [{who}] {r['source']} {r['rating'] or '-'}* {r['date']} {u}\n    E-themes: {ethemes}\n    {r['text']}\n\n")
json.dump(out, open(os.path.join(HERE, 'compare.json'), 'w'), indent=1)
open(os.path.join(HERE, 'compare.txt'), 'w').write('\n'.join(lines) + '\n')
print('\n'.join(lines))
