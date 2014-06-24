#!/bin/sh
#
# template.sh - basic shell script template
#
# Copyright (C) 2012-2014 Thomas Kemmer <tkemmer@computer.org>
#

# uncomment to exit if untested command fails
#set -e

# uncomment to trace commands
#set -x

# program name
PROGRAM="$(basename "$0")"

# usage information
usage=$(cat <<EOF
Usage: $PROGRAM [OPTION]... FILE...
Basic shell script template.

  -h          print this message and exit
EOF
)

# parse command line options
while getopts ":h" opt; do
    case $opt in
        h)
            echo "$usage"
            exit
            ;;
        *)
            echo "$usage" 2>&1
            exit 1
            ;;
    esac
done

shift $(($OPTIND - 1))

echo "$@"

exit 0
