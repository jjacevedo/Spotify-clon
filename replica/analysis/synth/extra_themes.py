"""Synthesizer step 3: two small themes the lenses did not count, used only in 'What is unsolved'.
Method: keyword candidates over all 1227 rows, then every hit read by hand; KEEP lists hold the
rows that plainly match. Run: python3 extra_themes.py -> extra_themes.json
"""
import csv, re, json, os, collections
HERE = os.path.dirname(os.path.abspath(__file__))
rows = list(csv.DictReader(open('/home/user/Spotify-clon/replica/reviews.csv', encoding='utf-8')))
KW = {
 'files_replaced_or_converted': r"replaced with|itunes match|\bmatched\b|matching|different recording|same recording|transcod|convert\w* (to|flac)|\balac\b|whatever it had in its database",
 'other_service_offline_fails': r"(youtube music|yt music|apple music|amazon music|deezer|tidal).{0,200}(offline|download)|(offline|download).{0,200}(youtube music|yt music|apple music|amazon music)",
}
hits = {k: [(i, r) for i, r in enumerate(rows) if re.search(p, r['text'], re.I)] for k, p in KW.items()}
if __name__ == '__main__':
    import sys
    if '--show' in sys.argv:
        for k, hs in hits.items():
            print('#####', k, len(hs))
            for i, r in hs:
                print(f"--- {i} {r['source']} {r['rating'] or '-'} {r['date']} {r['url']}\n   {r['text'][:700]}")

# Hand-read decisions (0-based row ids). Rejected hits: 693 (ads "replaced with" better ones), 1124 (self-host jargon),
# 1127 (praises Apple matching), 1188 (Spotify offline, already in offline_broken), 230/483 (praise),
# 1086/1106/1159 (no offline failure of another service), 1193 (Spotify offline; Apple tried for recs).
KEEP = {
 'files_replaced_or_converted': [1152, 1158, 1206, 1212],
 'other_service_offline_fails': [729, 730, 1220],
}
out = {}
for k, ids in KEEP.items():
    src = collections.Counter(rows[i]['source'] for i in ids)
    out[k] = {'n': len(ids), 'by_source': dict(src), 'thin': len(ids) < 3 or len(src) < 2,
              'candidates': len(hits[k]), 'urls': [rows[i]['url'] for i in ids]}
json.dump(out, open(os.path.join(HERE, 'extra_themes.json'), 'w'), indent=1)
if __name__ == '__main__':
    print(json.dumps({k: {x: v[x] for x in ('n', 'by_source', 'thin', 'candidates')} for k, v in out.items()}))
