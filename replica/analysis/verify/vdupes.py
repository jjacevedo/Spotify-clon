# Find exact and near-duplicate review texts in reviews.csv (token Jaccard >= 0.8 on word sets, texts >= 12 words).
import csv, re, itertools, json
rows = list(csv.DictReader(open('/home/user/Spotify-clon/replica/reviews.csv', newline='', encoding='utf-8')))
def toks(t): return set(re.findall(r"[a-z0-9']+", t.lower()))
T = [toks(r['text']) for r in rows]
pairs = []
for i, j in itertools.combinations(range(len(rows)), 2):
    a, b = T[i], T[j]
    if len(a) < 12 or len(b) < 12: continue
    jac = len(a & b) / len(a | b)
    if jac >= 0.8: pairs.append((i, j, round(jac, 2)))
for i, j, s in pairs:
    print(i, j, s, rows[i]['source'], rows[i]['date'], rows[j]['date'], '|', rows[i]['text'][:90])
urls = set(r['url'] for r in rows); print('rows', len(rows), 'unique urls', len(urls))
json.dump(pairs, open('dupes.json', 'w'))
