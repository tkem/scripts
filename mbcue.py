import argparse
import requests
import sys
import json
import re


def parse_cue(fp):
    cue = {}
    regex = re.compile(r"(TRACK\s+\w+|INDEX\s+\w+|REM\s+\w+|\w+)\s+(.*)")
    track = None
    for line in (s.strip() for s in fp.readlines() if s.strip()):
        m = regex.match(line)
        if not m:
            print(f'Skipping CUE sheet line "{line}"', file=sys.stderr)
        elif m[1].startswith("TRACK"):
            track = m[1]
            cue[track] = dict()
        elif track:
            cue[track][m[1]] = m[2]
        else:
            cue[m[1]] = m[2]
    return cue


def print_cue(cue, fp):
    # non-track items must come before track items
    for k, v in ((k, cue[k]) for k in cue if k != "FILE" and not k.startswith("TRACK")):
        print(k, v, file=fp)
    print("FILE", cue["FILE"], file=fp)
    for k, v in ((k, cue[k]) for k in cue if k.startswith("TRACK")):
        print(f"  {k} AUDIO", file=fp)
        for tk, tv in v.items():
            print(f"    {tk} {tv}", file=fp)


def update_cue(cue, data, discno=None):
    def credits(artists):
        return "".join(a["name"] + a.get("joinphrase", "") for a in artists)

    media = data.get("media", [])
    if len(media) < 1:
        raise Exception("Item contains no media")
    if len(media) == 1:
        discno = None
        tracks = media[0].get("tracks", [])
    else:
        discno = discno or int(cue["REM DISCNUMBER"])
        tracks = media[discno - 1].get("tracks", [])
    cue["PERFORMER"] = '"%s"' % credits(data["artist-credit"])
    cue["TITLE"] = '"%s"' % data["title"]
    if "barcode" in data:
        cue["CATALOG"] = data["barcode"]
    if "date" in data:
        cue["REM DATE"] = data["date"].partition("-")[0]
    if discno is not None:
        cue["REM TOTALDISCS"] = len(media)
        cue["REM DISCNUMBER"] = discno
    # if "asin" in data:
    #    cue["REM ASIN"] = data["asin"]
    for n, track in enumerate(tracks, 1):
        artists = track.get("artist-credit", data["artist-credit"])
        cue["TRACK %02d" % n]["PERFORMER"] = '"%s"' % credits(artists)
        cue["TRACK %02d" % n]["TITLE"] = '"%s"' % track.get("title")
        # ISRC DEU312300112


def get_mb_release_id(barcode):
    url = f"https://musicbrainz.org/ws/2/release/?query=barcode:{barcode}&fmt=json"
    data = requests.get(url=url).json()
    if "count" not in data or data["count"] == 0:
        raise Exception(f"No release found for barcode {barcode}")
    if data["count"] != 1:
        raise Exception(f"Multiple releases found for barcode {barcode}")
    return data["releases"][0]["id"]


def main():
    parser = argparse.ArgumentParser(description="mbcue")
    parser.add_argument("cue", metavar="CUESHEET", help="CUE sheet file")
    parser.add_argument("-b", "--barcode", help="disc barcode")
    parser.add_argument("-n", "--discno", type=int, help="disc number")
    parser.add_argument("-r", "--release-id", help="MusicBraint release ID")
    parser.add_argument("-v", "--verbose", action="store_true", help="verbose output")
    args = parser.parse_args()

    try:
        with open(args.cue) as fp:
            cue = parse_cue(fp)
        if args.release_id:
            mbid = args.release_id
        elif args.barcode:
            mbid = get_mb_release_id(args.barcode)
        else:
            mbid = get_mb_release_id(cue.get("CATALOG"))
        url = f"https://musicbrainz.org/ws/2/release/{mbid}"
        q = "?fmt=json&inc=artists+artist-credits+media+discids+recordings+isrcs"
        # print(url. file=sys.stderr)
        data = requests.get(url=url+q).json()
        # json.dump(data, sys.stderr, indent=2, sort_keys=True)
        update_cue(cue, data, args.discno)
        # some tools require DOS-style line endings for cue sheets
        out = open(sys.stdout.fileno(), mode="w", encoding="utf-8", newline="\r\n")
        print_cue(cue, out)
    except Exception as e:
        print(f"{parser.prog}: {args.cue}:", e, file=sys.stderr)
        exit(1)


if __name__ == "__main__":
    main()
