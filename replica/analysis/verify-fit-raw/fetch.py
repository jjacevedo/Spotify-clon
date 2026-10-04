import urllib.request, time, json, hashlib, sys
urls = [
 "https://support.spotify.com/us/article/autoplay/",
 "https://support.spotify.com/us/article/understanding-my-data/",
 "https://support.spotify.com/us/article/data-rights-and-privacy-settings/",
 "https://support.spotify.com/us/article/recent-activity/",
]
log=[]
for u in urls:
    try:
        req=urllib.request.Request(u, headers={"User-Agent":"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36","Accept-Language":"en-US"})
        r=urllib.request.urlopen(req, timeout=30)
        b=r.read()
        fn=hashlib.sha1(u.encode()).hexdigest()[:12]+'.html'
        open(fn,'wb').write(b)
        log.append({"url":u,"status":r.status,"final":r.geturl(),"file":fn,"bytes":len(b)})
    except Exception as e:
        log.append({"url":u,"error":repr(e)})
    print(log[-1]); sys.stdout.flush()
    time.sleep(3.6)
json.dump(log, open('fetch_log.json','w'), indent=1)
