#!/bin/sh
#
# ssh-md5sum.sh - compute md5sum over a directory tree via ssh
#
# Copyright (c) 2019 Thomas Kemmer <tkemmer@computer.org>
#

# program name
PROGRAM="$(basename "$0")"

# usage information
usage=$(cat <<EOF
Usage: $PROGRAM [OPTION]... TARGET...
Print MD5 checksums for a directory hierarchie, optionally via ssh.

  -h          print this message and exit
EOF
)

# parse command line options
while getopts ":h:" opt; do
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

for target; do
    dest=${target%%:*}
    path=${target#*:}
    if [ "$dest" != "$path" ]; then
        ssh "$dest" find "$path" -type f -exec md5sum '{}' \\\;
    else
        find "$path" -type f -exec md5sum '{}' \;
    fi
done
