#!/bin/sh

BEET="$HOME/.local/bin/beet"
CUETAG="cuetag"
MKDIR_P="mkdir -p"
SHNSPLIT="shnsplit"
TMPDIR=$(mktemp -d)

trap 'rm -fr "$TMPDIR"' EXIT
trap 'exit $?' INT TERM QUIT

for cuefile; do
    basedir=$(dirname "$cuefile")
    destdir="$TMPDIR"/"$basedir"
    basename=$(basename "$cuefile" .cue)
    # try to retrieve file name from cue sheet
    filename=$(grep '^FILE' "$cuefile" | sed -e 's/^[^"]*"//' -e 's/"[^"]*$//')
    if [ -f "$basedir"/"$filename" ]; then
        wavfile="$basedir"/"$filename"
    else
        echo "$filename: File not found" >&2
        exit 1
    fi
    # mirror folder structure for multi-disc releases
    $MKDIR_P "$destdir" || exit 1
    $SHNSPLIT -d "$destdir" -f "$cuefile" -o flac -a "$basename." "$wavfile"
    $CUETAG "$cuefile" "$destdir"/"$basename".*.flac
    # copy external album art for use with fetchart/embedart plugins
    cp "$basedir"/*.jpg "$basedir"/*.jpeg "$basedir"/*.png "$destdir" 2>/dev/null
done

$BEET import "$TMPDIR"
