#!/bin/sh

BEET="beet"
CUETAG="cuetag"
MKDIR_P="mkdir -p"
SHNSPLIT="shnsplit"
TMPDIR=$(mktemp -d)

trap 'rm -fr "$TMPDIR"' EXIT
trap 'exit $?' INT TERM QUIT

for cuefile; do
    basename=$(basename "$cuefile" .cue)
    basedir=$(dirname "$cuefile")
    destdir="$TMPDIR/$basedir"
    # get file name from cue sheet
    filename=$(grep '^FILE' "$cuefile" | sed -e 's/^[^"]*"//' -e 's/"[^"]*$//')
    if [ -f "$basedir/$filename" ]; then
        wavfile="$basedir/$filename"
    else
        echo "$filename: File not found" >&2
        exit 1
    fi
    # mirror folder structure for multi-disc releases
    $MKDIR_P "$destdir" || exit 1
    $SHNSPLIT -d "$destdir" -f "$cuefile" -o flac -a "$basename." "$wavfile" || cp "$wavfile" "$destdir/$basename.flac"
    # FIXME: track #0 handling
    rm -f "$destdir/$basename".00.flac
    $CUETAG "$cuefile" "$destdir/$basename".*.flac
done

$BEET import -t "$TMPDIR"
