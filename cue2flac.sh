#!/bin/sh
METAFLAC=metaflac

import_cuesheet () {
    $METAFLAC --remove-tag=CUESHEET "$1"
    $METAFLAC --set-tag-from-file=CUESHEET="$2" "$1"
}

for file; do
    dirname=$(dirname "$file")
    basename=$(basename "$file" ".cue")
    flacfile="$dirname/$basename.flac"
    import_cuesheet "$flacfile" "$file"
done
