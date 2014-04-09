#!/bin/sh
#
# beet-import.sh - import zip files into beets library
#
# Copyright (C) 2015 Thomas Kemmer <tkemmer@computer.org>
#
MKTEMP=mktemp
UNZIP=unzip
BEET=beet

# die [MESSAGE]...
die () {
    status=$?
    [ $# -gt 0 ] && echo "$0:" "$@" >&2
    [ $status -ne 0 ] && exit $status
    exit 255  # as in `perl -e "die()"`
}

# log MESSAGE...
log () {
    echo "$0:" "$@" >&2
}

toupper () {
    echo "$@" | tr '[:lower:]' '[:upper:]'
}

tolower () {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

for file; do
    if [ $(tolower "${file##*.}") = 'zip' ]; then
        TMPDIR=$($MKTEMP -d -t "$(basename $0).XXXXXXXXXX") || die
        trap 'rm -rf "$TMPDIR"' EXIT HUP INT PIPE TERM
        $UNZIP -d "$TMPDIR" "$file" || die
        $BEET import "$TMPDIR" || die
        rm -rf "$TMPDIR" || die
    else
        beet import "$file"
    fi
done
