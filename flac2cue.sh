#!/bin/sh
METAFLAC=metaflac

cuesheet () {
    $METAFLAC --show-tag=CUESHEET "$1" | sed -e "1s/^CUESHEET=//" -e '/^$/d'
}

for file; do
    dirname=$(dirname "$file")
    basename=$(basename "$file" ".flac")
    cuefile="$dirname/$basename.cue"

    if [ -n "$DEBUG" ]; then
        cuesheet "$file" | diff "$cuefile" -
    else
        cuesheet "$file" > "$cuefile"
    fi
done
