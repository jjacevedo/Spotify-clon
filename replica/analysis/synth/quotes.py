"""Synthesizer quote check: every quote used in fixes.draft.md must be an exact substring of the
`text` cell of the reviews.csv row with that url. Exits 1 on any miss. Writes quotes.verified.json
(key, url, quote, source, rating, date). Also scans fixes.draft.md for every quoted span that is
followed by a reviews.csv link and checks it too (see check_draft()).
Run: python3 quotes.py [--draft ../fixes.draft.md]
"""
import csv, json, os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__))
rows = list(csv.DictReader(open('/home/user/Spotify-clon/replica/reviews.csv', encoding='utf-8')))
by = {r['url']: r for r in rows}
AS = 'https://itunes.apple.com/{}/rss/customerreviews/page={}/id=324684580/sortby=mostrecent/{}#review-{}'
GP = 'https://play.google.com/store/apps/details?id=com.spotify.music&hl=en_{}&gl={}#review-{}'
HN = 'https://news.ycombinator.com/item?id={}'

Q = [
 # ---- what they hate ----
 ('ads', AS.format('us', 10, 'xml', 14616051292), 'Yall really put four ads in between every TWO songs???'),
 ('ads', GP.format('US', 'US', 6), 'roughly 2-3 minutes of ads per 3-5 minutes of music'),
 ('ftc', GP.format('IN', 'IN', 11), 'I can no longer choose songs freely from my Liked Songs/playlist.'),
 ('ftc', AS.format('us', 7, 'json', 14617030464), 'LET ME LISTEN TO MY SONGS IN ORDER'),
 ('bugs', GP.format('US', 'US', 16), 'The app crashes on me every other song'),
 ('bugs', AS.format('ca', 3, 'json', 14607593296), 'Would be a great app if it wasn’t for the constant bugs, crashes, and performance issues.'),
 ('price', AS.format('us', 3, 'xml', 14620111962), 'The price keeps going up on me and I’m starting to get upset by that.'),
 ('price', HN.format(40563837), "I'll be cancelling this month because I'm not getting enough value."),
 ('clutter', HN.format(39428119), 'I quit Spotify because I can’t customise the home page which pushes podcasts and music I’m not interested in.'),
 ('clutter', AS.format('nz', 7, 'xml', 14243562668), 'All those irrelevant pop ups for podcasts and shows I don’t want to listen'),
 ('ui', HN.format(45590991), 'I stopped using Spotify because of their constant UI churn.'),
 ('ui', HN.format(44083095), "I just simply can't find my way around the app anymore."),
 ('slow', AS.format('nz', 8, 'json', 14196583670), 'press one song and it takes nearly 30 seconds to play or to load'),
 ('adspaid', AS.format('nz', 5, 'xml', 14355942538), 'why am i getting ads on a premium account?'),
 ('adspaid', HN.format(45972340), 'I’m paying to not have ads, and you still serve me ads.'),
 ('playback', AS.format('us', 7, 'json', 14617041160), 'the playback stops by itself like 5-7 times on my way to work'),
 ('playback', AS.format('ca', 8, 'xml', 14583851300), 'The android version of this app pauses randomly during my work day.'),
 ('recs', AS.format('nz', 5, 'xml', 14360268231), 'the algorithm keeps giving me the same songs over and over again'),
 ('recs', HN.format(34469711), 'Daily playlists are just several of my favorite artists shuffled.'),
 ('offline', AS.format('gb', 2, 'json', 14614101383), 'I’ve tried playing my downloaded music offline but it won’t play unless I’m connected to WiFi or on my 4/5g.'),
 ('offline', HN.format(34695080), 'I\'ve had many flights where my "offline" library won\'t play'),
 ('login', AS.format('gb', 4, 'json', 14607959550), 'now I can’t log back in as it says something went wrong'),
 ('inject', AS.format('us', 4, 'json', 14619602976), 'is adding song not on the list. I made the list for a reason.'),
 ('inject', HN.format(44334326), 'They would try to insert songs to my playlists where they don’t belong.'),
 ('artistpay', AS.format('nz', 7, 'xml', 14263660522), 'Spotify needs to pay artists what they are worth'),
 ('artistpay', HN.format(46712608), 'their treatment of artists is abominable'),
 ('removed', HN.format(35636121), 'So many tracks in my playlists are no longer available on the service.'),
 ('removed', AS.format('ca', 1, 'xml', 14620611771), 'they don’t tell you when you song gets taken off it just disappears from the playlist it was on'),
 ('billing', AS.format('gb', 6, 'json', 14603746577), 'I don’t think customers should have to fight this hard to get their own money back'),
 ('billing', HN.format(41859836), 'I had to "continue to cancel"'),
 ('shuffle', AS.format('gb', 7, 'xml', 14600507830), 'I get the same sings every day on a playlist of around 1500 songs'),
 ('shuffle', HN.format(49523937), 'I\'m aware last year Spotify announced "fewer repeats" shuffle - but it doesn\'t work, or isn\'t sufficient anyway.'),
 ('icon', AS.format('nz', 10, 'json', 14138031207), 'so hard to find Spotify icon on home screen'),
 ('paywall', AS.format('ca', 8, 'xml', 14581806561), 'It’s the best if you have premium the opposite if you don’t'),
 ('devices', AS.format('ie', 1, 'json', 14607828148), 'connecting to things like speakers shouldn’t cost money'),
 ('aimusic', AS.format('nz', 4, 'xml', 14432688196), 'Spotify should let us know if a song is AI generated.'),
 ('aimusic', AS.format('nz', 8, 'json', 14222769708), 'there was no way for me to filter out and avoid all of the terrible AI music that is clogging up the platform'),
 ('queue', HN.format(47430204), 'how hard it is to add something to your current playing queue'),
 ('queue', AS.format('us', 3, 'xml', 14620191605), 'you guys need to let me queue a song next like apple music has instead of it being added to the bottom of the queue'),
 ('prompts', AS.format('us', 9, 'xml', 14616377763), 'this is the 1,000th time they have asked me to review their app'),
 ('prompts', AS.format('gb', 9, 'xml', 14595122095), 'being asked to rate the app with a stupid pop up every single day is incredibly irritating'),
 ('audiobook', AS.format('gb', 7, 'xml', 14600885705), 'informed me that my hours (!) have been used up'),
 ('aifeat', AS.format('ie', 7, 'json', 14259905328), 'remove all the ai features that no one ever asked for'),
 ('car', AS.format('nz', 10, 'json', 14092118927), 'CarPlay doesn’t work properly. The song on car infotainment does not match the song playing.'),
 ('podcast', AS.format('gb', 7, 'xml', 14601013313), 'the app has suddenly started playing podcasts newest to oldest'),
 ('libloss', AS.format('nz', 1, 'json', 14614433626), 'It removes a lot of my liked songs unsure why'),
 ('kids', HN.format(37791138), 'my kids used it to watch stupid TikTok videos all the time'),
 ('ipad', AS.format('nz', 6, 'xml', 14345061152), 'IT STILL CRASHES THE APP WHILE TRYING TO SWITCH FROM ONE SIDE TO THE OTHER!!'),
 ('lock', AS.format('us', 6, 'xml', 14618566405), 'Spotify removed the function to play it in locked screen mode'),
 ('location', AS.format('ie', 4, 'xml', 14462322496), "Your location doesn't match your profile, upgrade to premium to listen internationally."),
 # ---- what is missing ----
 ('upload', HN.format(39428119), 'The one major gripe is not being able to upload my own songs'),
 ('upload', HN.format(41221819), 'I moved my family plan from Spotify because they still don’t have an easy to use music locker solution.'),
 ('localfiles', HN.format(39428365), 'Local files in Spotify is extremely iffy. It has forgot them many times for me.'),
 ('localfiles', HN.format(42113400), 'it just allows you to access local files per device'),
 ('own', HN.format(46776986), 'At the end, I had nothing to show for it.'),
 ('own', GP.format('US', 'US', 17), "can't get my 7000 songs off the damn app without starting completely over on something else, no transfer apps work."),
 ('export', HN.format(41119283), 'There is no way to export playlists.'),
 ('export', HN.format(46777110), 'I was very annoyed that I had to pay a 3rd party company to export this data'),
 ('libtools', AS.format('us', 3, 'xml', 14620065931), 'We need smart playlists.'),
 ('libtools', AS.format('ca', 1, 'xml', 14620004065), 'cannot search within my own playlist.'),
 ('libtools', AS.format('us', 4, 'json', 14619890522), 'needs a dragging scrolling bar on the liked songs library'),
 ('history', AS.format('nz', 5, 'xml', 14359879282), 'I would like to know what the track play counts are.'),
 ('history', HN.format(40472957), 'Why can’t I see a stream of the songs I played so I can easily find what I recently played and play it again?'),
 ('shreq', AS.format('gb', 1, 'json', 14619811598), 'I’d like to be able to just randomise my entire catalogue I have saved on my account'),
 ('shreq', AS.format('us', 7, 'json', 14617332175), 'I really wish that it was possible to shuffle the queue'),
 ('shreq', AS.format('gb', 9, 'xml', 14594404521), 'should be a function that it will only play a song once until the playlists has looped back round again'),
 ('hide', HN.format(38520656), "I don't like that I can't hide or disable audiobooks or podcasts."),
 ('lossless', AS.format('us', 7, 'json', 14617292590), 'Not a good quality like Dolby or 4 k sound'),
 ('lossless', HN.format(34596537), "they don't have offer a lossless quality stream"),
 ('lyrics', AS.format('gb', 6, 'json', 14607276368), 'i need the lyrics back'),
 ('noton', HN.format(39968033), "I have a fair number of sentimental tracks that I've carried with me in my collection for decades which aren't on streaming sites."),
 ('noton_risk', AS.format('ca', 5, 'xml', 14601011908), 'I wish Spotify would let people upload songs and remixes they like on YouTube but don’t exist on Spotify.'),
 # ---- unsolved ----
 ('u_host', HN.format(42513052), 'I’ve been searching for services that host personal music collections, but there doesn’t seem to be much available.'),
 ('u_host', HN.format(42513052), 'Some existing services allow you to add your own music files, like MP3s, but this often feels like a second-class citizen.'),
 ('u_effort', HN.format(49518972), 'if something takes more than a few clicks to go from zero to music that leaves 95% of users out!'),
 ('u_effort', HN.format(43713614), 'i really have no idea what any of these words mean.'),
 ('u_match', HN.format(41311984), "Tracks I'd ripped from original CDs were replaced with different recordings."),
 ('u_match', HN.format(42113467), "spotify used whatever it had in its database with the same name/artist, which wasn't always the same recording or even the same song"),
 ('u_offline', HN.format(49523451), 'the "download for offline" functionality is incredibly broken'),
 ('u_offline', HN.format(39776396), 'I have my library downloaded, why is the UI "loading" and blocking? It should be instant.'),
 ('u_removed', GP.format('US', 'US', 2), "It would be amazing if y'all could add a way to let us know when a song is removed from a playlist."),
 ('u_removed', HN.format(39967357), 'A music service that hides their catalog changes by subtly modifying my playlists is a no-go.'),
 ('u_disc', HN.format(46518747), 'the thing I miss most is music discovery via radios / discover weekly'),
 ('u_disc', HN.format(48374133), 'Actually owning music I listen to now feels great, but I missed the automatic recommendations.'),
 ('u_shuffle', AS.format('nz', 5, 'xml', 14388226533), 'I have a playlist with over 2000 songs and yet I still hear the same song’s multiple times a day.'),
 ('u_kids', HN.format(42861610), 'There are no parental controls or any other method for blocking podcasts.'),
 # ---- fix plan ----
 ('fx_ftc', AS.format('gb', 2, 'json', 14613907575), 'you have to pay for your playlist to be lay in order'),
 ('fx_inject', AS.format('au', 1, 'json', 14616895632), 'I JUST WANT TO LISTEN TO THE SONGS IN MY PLAYLIST!!'),
 ('fx_quiet', HN.format(35462336), 'via full-screen modal popups in the app with no way to prevent them'),
 ('fx_shuffle', AS.format('ca', 1, 'xml', 14617171320), 'Shuffles the same few songs in my 600 song playlist'),
 ('fx_offline', AS.format('ca', 3, 'json', 14607434628), 'I have to redownload every dam song every 3 days just for when I’m out of service'),
 ('fx_locker', HN.format(37792608), "you can't upload to your own cloud library. Apple Music and YouTube Music both let you do that."),
 ('fx_hostage', AS.format('us', 6, 'xml', 14618139577), 'every song is blacked out and wont let me listen to it'),
 ('fx_hostage', HN.format(47021054), 'i felt they used my library to hold me hostage'),
 ('fx_libtools', HN.format(40472070), 'I want control over how my library is organized and made accessible to me.'),
 # ---- notes for later phases ----
 ('n_price', GP.format('US', 'US', 1), 'maybe lower the price instead of increasing an extra dollar every year for premium'),
 ('n_family', AS.format('ca', 5, 'xml', 14601979221), 'Family plan is almost 50% more than the competition!'),
 ('n_cancel', HN.format(41859836), 'I think I proceeded through 7-8 pages before my subscription was actually canceled'),
]

def check(entries):
    bad, out = [], []
    for k, u, q in entries:
        r = by.get(u)
        if r is None:
            bad.append((k, u, 'URL NOT IN reviews.csv')); continue
        if q not in r['text']:
            bad.append((k, u, q)); continue
        if '...' in q or '…' in q:
            bad.append((k, u, 'ELLIPSIS IN QUOTE: ' + q)); continue
        out.append({'key': k, 'url': u, 'quote': q, 'source': r['source'], 'rating': r['rating'], 'date': r['date']})
    return bad, out

def check_draft(path):
    """Find every “quote” ([source ...](url)) pair in the draft and verify it."""
    txt = open(path, encoding='utf-8').read()
    pat = re.compile(r'“([^”]+)”\s*\(\[[^\]]*\]\((https?://[^)\s]+)\)\)')
    pairs = [( 'draft', m.group(2), m.group(1)) for m in pat.finditer(txt)]
    return pairs

if __name__ == '__main__':
    bad, ok = check(Q)
    json.dump(ok, open(os.path.join(HERE, 'quotes.verified.json'), 'w'), indent=1, ensure_ascii=False)
    print(f'list: {len(ok)} ok, {len(bad)} bad')
    for b in bad: print('  BAD', b)
    if '--draft' in sys.argv:
        p = sys.argv[sys.argv.index('--draft') + 1]
        pairs = check_draft(p)
        b2, ok2 = check(pairs)
        print(f'draft: {len(pairs)} quote/link pairs found, {len(ok2)} ok, {len(b2)} bad')
        for b in b2: print('  BAD', b)
        bad += b2
    sys.exit(1 if bad else 0)
