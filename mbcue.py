import requests
import sys
import json

mbid = sys.argv[1]

def credits(artists):
    return "".join(a["name"] + a.get("joinphrase", "") for a in artists)

url = f"https://musicbrainz.org/ws/2/release/{mbid}?fmt=json&inc=artists+artist-credits+media+discids+recordings+isrcs"

resp = requests.get(url=url)
data = resp.json()

performer = credits(data["artist-credit"])
title = data["title"]

# DISCID
print('PERFORMER "%s"' % performer)
print('TITLE "%s"' % title)
if "barcode" in data:
    print ("CATALOG", data["barcode"])
if "date" in data:
    print("REM DATE", data["date"].partition("-")[0])
# DISCNUMBER
# TOTALDISCS
if "asin" in data:
    print("REM ASIN", data["asin"])
for n, media in enumerate(data.get("media", []), 1):
    # TODO: replace non-POSIX characters
    if len(data["media"]) > 1:
        print('FILE "%s - %s #%d.flac" WAVE' % (performer, title, n))
    else:
        print('FILE "%s - %s.flac" WAVE' % (performer, title))
    for track in media.get("tracks", []):
        artists = track.get("artist-credit", data["artist-credit"])
        print('  TRACK %02d AUDIO' % track.get("position"))
        print('    PERFORMER "%s"' % credits(artists))
        print('    TITLE "%s"' % track.get("title"))
        #ISRC DEU312300112
        #INDEX 01 02:15:28
