#!/bin/sh

MEDIA_DIRS="Music Pictures Videos"
RSYNC_OPTS="-a --delete --exclude=.* --exclude=tmp"

if [ $# -lt 1 ]; then
    echo "Usage: $0 [OPTION]... DEST" >&2
    exit 1
fi

while [ $# -gt 1 ]; do
    RSYNC_OPTS="$RSYNC_OPTS $1"
    shift
done

DEST="$1"

# special handling for dd-wrt
case $DEST in
    *192.168.1.1:*)
        RSYNC_OPTS="$RSYNC_OPTS --rsync-path=/opt/usr/bin/rsync-ld"
        ;;
esac

for d in $MEDIA_DIRS; do
    rsync $RSYNC_OPTS "$HOME/$d/" "$DEST/$d/"
done
