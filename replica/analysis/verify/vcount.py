"""verify-counts: independent recount of fixes.draft.md from replica/reviews.csv.

Method: one verifier read EVERY row of reviews.csv in full (vdump.py) and hand-coded it in labels.txt
(core = rating<=3 or hacker-news: all themes; rating>=4: complaint themes + two praise codes).
No analyst script, label file or keyword list was reused for the coding. This script only tallies labels.txt,
then compares each theme with the draft's figure and with the evidence lens's URL list (synth/recount.json)
to report overlap (used only to pick rows for adjudication re-reads).
Run: python3 vcount.py  -> verify-counts.json + printed table
"""
import csv, json, re, collections, os
HERE = os.path.dirname(os.path.abspath(__file__))
rows = list(csv.DictReader(open('/home/user/Spotify-clon/replica/reviews.csv', newline='', encoding='utf-8')))
L = collections.defaultdict(set)
seen = set()
for line in open(os.path.join(HERE, 'labels.txt'), encoding='utf-8'):
    line = line.split('#')[0].strip()
    if not line: continue
    i, codes = line.split(':', 1)
    i = int(i); seen.add(i)
    for c in codes.split():
        if c != '-': L[i].add(c)
def is_core(r): return r['source'] == 'hacker-news' or int(r['rating']) <= 3
core_ids = [i for i, r in enumerate(rows) if is_core(r)]
missing_core = [i for i in core_ids if i not in seen]
FTC = {'ftc_pick', 'ftc_skip', 'ftc_order', 'ftc_repeat', 'ftc_seek', 'ftc_queue'}
for i in list(L):
    if L[i] & FTC: L[i].add('ftc')
def ids(code, scope='all'):
    out = [i for i in L if code in L[i]]
    if scope == 'core': out = [i for i in out if is_core(rows[i])]
    if scope == 'high': out = [i for i in out if not is_core(rows[i])]
    return sorted(out)
def src(idl):
    c = collections.Counter(rows[i]['source'] for i in idl)
    return {k: c[k] for k in ('app-store', 'google-play', 'hacker-news') if c[k]}
def thin(idl): return len(idl) < 3 or len(src(idl)) < 2
# draft figures: (label, my code, draft total, draft core, draft high or None if 4-5* not scanned, draft source split)
DRAFT = [
 ('S2.1 ads', 'ads', 208, 131, 77, {'app-store':175,'google-play':26,'hacker-news':7}),
 ('S2.2 free-tier control', 'ftc', 116, 88, 26, {'app-store':89,'google-play':26,'hacker-news':1}),
 ('S2.3 bugs/crashes', 'bugs', 86, 86, None, {'app-store':72,'google-play':11,'hacker-news':3}),
 ('S2.4 price', 'price', 82, 62, 20, {'app-store':70,'google-play':4,'hacker-news':8}),
 ('S2.4b price increases', 'price_inc', 31, 28, 3, {'app-store':25,'google-play':1,'hacker-news':5}),
 ('S2.5 clutter/promos', 'clutter', 49, 46, 3, {'app-store':21,'google-play':4,'hacker-news':24}),
 ('S2.6 UI/redesign/navigation', 'ui', 40, 38, 2, {'app-store':21,'google-play':2,'hacker-news':17}),
 ('S2.7 slow/battery', 'slow', 32, 32, None, {'app-store':27,'google-play':3,'hacker-news':2}),
 ('S2.8 paying and still ads', 'paid_ads', 33, 30, 3, {'app-store':22,'google-play':5,'hacker-news':6}),
 ('S2.9 playback stops', 'playback', 28, 28, None, {'app-store':22,'google-play':5,'hacker-news':1}),
 ('S2.10 recs poor', 'recs', 27, 27, None, {'app-store':15,'google-play':2,'hacker-news':10}),
 ('S2.11 offline fails', 'offline', 27, 26, 1, {'app-store':9,'google-play':4,'hacker-news':14}),
 ('S2.12 login', 'login', 25, 25, None, {'app-store':25}),
 ('S2.13 playlist injection', 'inject', 33, 25, 6, {'app-store':17,'google-play':8,'hacker-news':8}),
 ('S2.14 artist pay/politics', 'politics', 23, 23, None, {'app-store':16,'google-play':1,'hacker-news':6}),
 ('S2.15 catalogue removals', 'removals', 27, 23, 4, {'app-store':6,'google-play':2,'hacker-news':19}),
 ('S2.16 billing/support', 'billing', 22, 22, None, {'app-store':19,'google-play':2,'hacker-news':1}),
 ('S2.17 shuffle not random', 'shuffle', 25, 17, 8, {'app-store':19,'google-play':1,'hacker-news':5}),
 ('S2.18 app icon', 'icon', 18, 15, 3, {'app-store':17,'hacker-news':1}),
 ('S2.19 generic paywall', 'paywall', 15, 15, None, {'app-store':15}),
 ('S2.20 devices/connect', 'devices', 17, 14, 3, {'app-store':14,'google-play':1,'hacker-news':2}),
 ('S2.20b devices paywall', 'devices_pay', 4, 4, None, {'app-store':4}),
 ('S2.21 AI music', 'ai_music', 13, 13, None, {'app-store':10,'hacker-news':3}),
 ('S2.22 queue UX', 'queue', 16, 13, 3, {'app-store':7,'google-play':5,'hacker-news':4}),
 ('S2.23 rate prompts', 'rate', 12, 11, 1, {'app-store':12}),
 ('S2.24 audiobook hours', 'audiobook', 17, 11, 6, {'app-store':14,'google-play':2,'hacker-news':1}),
 ('S2.25 AI features', 'ai_feat', 9, 9, None, {'app-store':6,'google-play':1,'hacker-news':2}),
 ('S2.26 car', 'car', 8, 8, None, {'app-store':5,'google-play':1,'hacker-news':2}),
 ('S2.27 podcast mgmt', 'podcast', 8, 8, None, {'app-store':8}),
 ('S2.28 library data loss', 'data_loss', 7, 7, None, {'app-store':5,'google-play':2}),
 ('S2.29 kids', 'kids', 6, 6, None, {'hacker-news':6}),
 ('S2.30 iPad', 'ipad', 4, 4, None, {'app-store':4}),
 ('S2.31 lock screen', 'lockscreen', 4, 3, 1, {'app-store':3,'google-play':1}),
 ('S2.32 travel/location', 'travel', 6, 3, 3, {'app-store':5,'hacker-news':1}),
 ('S3.1 upload own files', 'upload', 34, 30, 4, {'app-store':5,'google-play':1,'hacker-news':28}),
 ('S3.1b Local Files clunky', 'localfiles', 11, 11, None, {'google-play':1,'hacker-news':10}),
 ('S3.1c not on streaming (market)', 'notonstreaming', 18, None, None, {'app-store':6,'hacker-news':12}),
 ('S3.2 own not rent', 'own', 30, 30, None, {'app-store':4,'google-play':2,'hacker-news':24}),
 ('S3.2b export/transfer', 'export', 7, 7, None, {'app-store':1,'google-play':2,'hacker-news':4}),
 ('S3.3 library tools', 'libtools', 18, 8, 10, {'app-store':12,'google-play':2,'hacker-news':4}),
 ('S3.4 history/play counts', 'history', 9, 7, 2, {'app-store':4,'hacker-news':5}),
 ('S3.5 shuffle-control requests', 'shuffle_req', 9, None, None, {'app-store':6,'hacker-news':3}),
 ('S3.6 music-only mode', 'music_only', 10, None, None, {'app-store':5,'hacker-news':5}),
 ('S3.7 lossless', 'lossless', 11, 9, 2, {'app-store':3,'hacker-news':8}),
 ('S3.8 lyrics', 'lyrics', 3, 3, None, {'app-store':3}),
 ('S4 self-hosting effort', 'selfhost_effort', 17, 17, None, {'hacker-news':17}),
 ('S4 self-host stacks', 'selfhost_stack', 17, 17, None, {'hacker-news':17}),
 ('S4 U3 replaced/converted', 'replaced', 4, 4, None, {'hacker-news':4}),
 ('S4 U4 offline other apps', 'offline_other', 3, 3, None, {'hacker-news':3}),
 ('S4 U6 discovery missed', 'discovery_missed', 16, 16, None, {'hacker-news':16}),
 ('S5 F7 locked out after cancel', 'hostage', 3, None, None, {'app-store':2,'hacker-news':1}),
 ('S7 gift cards', 'gift', 3, None, None, {'app-store':3}),
 ('praise discovery (4-5*)', 'praise_discovery', 34, None, 34, {'app-store':31,'google-play':3}),
 ('praise background play (4-5*)', 'praise_background', 13, None, 13, {}),
]
R = json.load(open(os.path.join(HERE, '..', 'synth', 'recount.json')))
url2i = {r['url']: i for i, r in enumerate(rows)}
EVMAP = {'ads':'ads','ftc':'free_tier_control','bugs':'bugs_crashes','price':'price','price_inc':'price_increase','clutter':'clutter_promos',
 'ui':'ui_navigation','slow':'slow','paid_ads':'ads_while_paying','playback':'playback_reliability','recs':'recs_bad','offline':'offline_broken',
 'login':'login_account','inject':'playlist_injection','politics':'artist_pay_politics','removals':'catalogue_removals','billing':'billing_support',
 'shuffle':'shuffle_not_random','icon':'app_icon','paywall':'paywall_generic','devices':'devices_connect','devices_pay':'devices_paywall',
 'ai_music':'ai_music','queue':'queue_ux','rate':'review_prompts','audiobook':'audiobook_hours','ai_feat':'ai_features','car':'car',
 'podcast':'podcast_mgmt','data_loss':'library_data_loss','kids':'kids_content','ipad':'ipad_tablet','lockscreen':'lockscreen_background',
 'travel':'location_travel','upload':'own_music_upload','localfiles':'local_files_clunky','own':'ownership_export','export':'export_transfer',
 'libtools':'library_tools','history':'listening_history','lossless':'audio_quality','lyrics':'lyrics','selfhost_effort':'selfhost_effort',
 'selfhost_stack':'selfhost_movers','discovery_missed':'discovery_missed'}
out = {'method': __doc__, 'labelled_rows': len(seen), 'core_rows': len(core_ids), 'core_rows_unlabelled': missing_core, 'themes': {}}
print(f"labelled rows {len(seen)}; core {len(core_ids)}; core unlabelled {len(missing_core)}")
print(f"{'theme':34} {'draft':>6} {'mine':>5} {'core':>5} {'high':>5}  {'my sources':40} {'diff%':>6} thin(me) | evid∩mine evid_only mine_only")
for lab, code, dn, dcore, dhigh, dsrc in DRAFT:
    a = ids(code); c = ids(code, 'core'); h = ids(code, 'high')
    # when the draft did not scan 4-5*, compare like with like (core only)
    mine_cmp = len(c) if (dhigh is None and dcore is not None) else len(a)
    diff = (mine_cmp - dn) / dn * 100 if dn else 0
    ev = None; inter = eonly = monly = None
    if code in EVMAP and EVMAP[code] in R['themes']:
        ev = set(url2i[u] for u in R['themes'][EVMAP[code]]['urls'])
        mineset = set(c) if (dhigh is None and dcore is not None) else set(a)
        inter, eonly, monly = len(ev & mineset), sorted(ev - mineset), sorted(mineset - ev)
    out['themes'][lab] = {'code': code, 'draft_n': dn, 'draft_core': dcore, 'draft_high': dhigh, 'draft_src': dsrc,
        'mine_all': len(a), 'mine_core': len(c), 'mine_high': len(h), 'mine_compared': mine_cmp, 'mine_src_all': src(a), 'mine_src_core': src(c),
        'diff_pct': round(diff, 1), 'thin_mine': thin(a), 'evidence_overlap': inter, 'evidence_only_ids': eonly, 'mine_only_ids': monly,
        'urls': [rows[i]['url'] for i in a]}
    s = src(c) if (dhigh is None and dcore is not None) else src(a)
    print(f"{lab:34} {dn:>6} {mine_cmp:>5} {len(c):>5} {len(h):>5}  {str(s):40} {diff:>6.0f} {str(thin(a)):5} | {inter} {len(eonly) if eonly is not None else '-'} {len(monly) if monly is not None else '-'}")
json.dump(out, open(os.path.join(HERE, 'verify-counts.json'), 'w'), indent=1)
