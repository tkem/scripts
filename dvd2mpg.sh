#!/bin/sh
#
# dvd2mpg.sh - convert DVD tracks to MPEG files
#
# Copyright (C) 2019 Thomas Kemmer <tkemmer@computer.org>
#

# uncomment to exit if untested command fails
#set -e

# uncomment to trace commands
#set -x

# program name
PROGRAM="$(basename "$0")"

# program options
DEVICE="/dev/dvd"
LSDVD="lsdvd"
MPLAYER="mplayer -nocache -noidx"

# usage information
usage=$(cat <<EOF
Usage: $PROGRAM [OPTION]...
Convert DVD to MPGE files.

  -d DEVICE   DVD device [$DEVICE]
  -h          print this message and exit
  -t TITLE    DVD title
EOF
)

# parse command line options
while getopts ":d:ht:" opt; do
    case $opt in
        d)
            DEVICE="$OPTARG"
            ;;
        h)
            echo "$usage"
            exit
            ;;
        t)
            TITLE="$OPTARG"
            ;;
        *)
            echo "$usage" 2>&1
            exit 1
            ;;
    esac
done

shift $(($OPTIND - 1))

if [ -z "$TITLE" ]; then
    TITLE=$($LSDVD "$DEVICE" | grep '^Disc Title:' | cut -d ' ' -f 3-)
fi

NTRACKS=$($LSDVD "$DEVICE" | grep '^Title:' | wc -l)
for i in $(seq 1 $NTRACKS); do
    outfile=$(printf "$TITLE-%02d.mpg" $i)
    $MPLAYER -dvd-device "$DEVICE" -dumpstream dvd://$i -dumpfile "$outfile"
done

exit 0
