#!/bin/sh

RSYNC_OPTS="-a --delete --exclude='.*' --exclude=tmp"

while [ $# -gt 2 -a ! -d $1 ]; do
    RSYNC_OPTS="$RSYNC_OPTS $1"
    shift
done

if [ $# -lt 3 -o ! -d $1 ]; then
    echo "Usage: $0 [OPTION]... SRC DEST DIR..." >&2
    exit 1
fi

SRC="$1"
DEST="$2"
shift 2

# special handling for dd-wrt
case $DEST in
    /*)
        ;;
    *)
        RSYNC_OPTS="$RSYNC_OPTS --rsync-path=/opt/usr/bin/rsync-ld"
        ;;
esac

for d in "$@"; do
    rsync $RSYNC_OPTS "$SRC/$d/" "$DEST/$d/"
done
