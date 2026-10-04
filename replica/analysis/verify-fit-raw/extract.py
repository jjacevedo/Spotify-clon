import json, re
from html.parser import HTMLParser
BLOCK=set('address article aside blockquote br dd div dl dt fieldset figcaption figure footer form h1 h2 h3 h4 h5 h6 header hr li main nav ol p pre section table tbody td tfoot th thead tr ul button img svg picture video audio iframe input select textarea label option'.split())
class T(HTMLParser):
    def __init__(s):
        super().__init__(convert_charrefs=True); s.parts=[]; s.skip=0
    def handle_starttag(s,tag,a):
        if tag in('script','style','noscript','template'): s.skip+=1
        if tag in BLOCK: s.parts.append(' ')
    def handle_endtag(s,tag):
        if tag in('script','style','noscript','template') and s.skip: s.skip-=1
        if tag in BLOCK: s.parts.append(' ')
    def handle_data(s,d):
        if not s.skip: s.parts.append(d)
def vis(raw):
    p=T(); p.feed(raw); return re.sub(r'\s+',' ',''.join(p.parts)).strip()
log=json.load(open('fetch_log.json'))
out={}
for r in log:
    raw=open(r['file'],encoding='utf-8',errors='replace').read()
    v=vis(raw)
    m=re.search(r'"updatedAt":"([0-9-]{10})', raw)
    out[r['url']]={'final':r['final'],'updatedAt':m.group(1) if m else None,'text':v}
json.dump(out, open('texts.json','w'), indent=1)
for u,o in out.items():
    s=o['text']
    i=s.find('Manage your account Your profile, payment and more.')
    j=s.find('Was this article helpful?')
    print('=====',u,'->',o['final'],'updatedAt',o['updatedAt'])
    print(s[i+50:j][:3500] if i>=0 and j>i else s[:2500])
