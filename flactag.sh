#!/bin/sh
METAFLAC=metaflac

if [ $# -lt 2 ]; then
    echo "Usage: $0 TAGNAME FILE..." >&2
    exit 1
fi

tag="$1"
shift

for file; do
    $METAFLAC --show-tag="$tag" "$file" | sed -e "1s/^$tag=//"
done
