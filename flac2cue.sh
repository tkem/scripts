#!/bin/sh

DEBUG=

for file; do
    dirname=$(dirname "$file")
    basename=$(basename "$file" ".flac")
    cuefile="$dirname/$basename.cue"

    if [ -n "$DEBUG" ]; then
        echo $cuefile
        metaflac --show-tag=CUESHEET "$file" | sed s/CUESHEET=// | diff "$cuefile" -
    else
        metaflac --show-tag=CUESHEET "$file" | sed s/CUESHEET=// > "$cuefile"
    fi
done
