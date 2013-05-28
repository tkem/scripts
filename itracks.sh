#!/bin/sh
#
# template.sh - shell script template
#
# Copyright (C) 2012 Thomas Kemmer <tkemmer@computer.org>
#

# uncomment to exit if untested command fails
#set -e

# uncomment to trace commands
#set -x




# TITLE
#     Track/Work name
# VERSION
#     The version field may be used to differentiate multiple versions of the same track title in a single collection. (e.g. remix info)
# ALBUM
#     The collection name to which this track belongs
# TRACKNUMBER
#     The track number of this piece if part of a specific larger collection or album
# ARTIST
#     The artist generally considered responsible for the work. In popular music this is usually the performing band or singer. For classical music it would be the composer. For an audio book it would be the author of the original text.
# PERFORMER
#     The artist(s) who performed the work. In classical music this would be the conductor, orchestra, soloists. In an audio book it would be the actor who did the reading. In popular music this is typically the same as the ARTIST and is omitted.
# COPYRIGHT
#     Copyright attribution, e.g., '2001 Nobody's Band' or '1999 Jack Moffitt'
# LICENSE
#     License information, eg, 'All Rights Reserved', 'Any Use Permitted', a URL to a license such as a Creative Commons license ("www.creativecommons.org/blahblah/license.html") or the EFF Open Audio License ('distributed under the terms of the Open Audio License. see http://www.eff.org/IP/Open_licenses/eff_oal.html for details'), etc.
# ORGANIZATION
#     Name of the organization producing the track (i.e. the 'record label')
# DESCRIPTION
#     A short text description of the contents
# GENRE
#     A short text indication of music genre
# DATE
#     Date the track was recorded
# LOCATION
#     Location where track was recorded
# CONTACT
#     Contact information for the creators or distributors of the track. This could be a URL, an email address, the physical address of the producing label.
# ISRC
#     ISRC number for the track; see the ISRC intro page for more information on ISRC numbers. 


METAFLAC=metaflac
ID3V2=id3v2
UNZIP=unzip

BASEDIR="$HOME/Music"
FORMAT='$ARTIST/$ALBUM/$TRACKNUMBER $TITLE'
PADDING=2
TMPDIR="/tmp/$(basename $0).$$"
VARIOUS="Various Artists"

die () {
    [ "$@" ] && echo "$0:" "$@" >&2
    exit 1
}

warn () {
    echo "$0:" "$@" >&2
}

info () {
    [ ${VERBOSE:-0} -ge 1 ] && echo "$0:" "$@" >&2
}

debug () {
    [ ${VERBOSE:-0} -ge 2 ] && echo "$0:" "$@" >&2
}

toupper () {
    echo "$@" | tr '[:lower:]' '[:upper:]'
}

tolower () {
    echo "$@" | tr '[:upper:]' '[:lower:]'
}

mungename () {
    echo "$@" | tr / - | tr -d "\"'?*[:cntrl:]"
}

fixpath () {
    echo "$@" | sed -e 's:^[[:space:]]*::' -e 's:[[:space:]]*$::' -e 's:[[:space:]]*//*[[:space:]]*:/:g'
}

install_file () {
    srcpath="$1"
    ext="$2"

    while IFS='=' read tag value; do
        case $tag in
            TITLE|ALBUM|ARTIST|GENRE|DATE)
                eval $tag="\${$tag:=$(mungename $value)}"
                ;;
            TRACKNUMBER)
                # expr interprets numbers as decimal, even in case of leading 0s
                TRACKNUMBER=${TRACKNUMBER:=$(expr ${STARTNUMBER:-1} + $value - 1)}
                ;;
            *)
                debug "Ignoring tag '$tag'"
                ;;
        esac
    done

    if [ "$TRACKNUMBER" -a "$PADDING" ]; then
        TRACKNUMBER=$(printf "%0.${PADDING}d" $TRACKNUMBER)
    fi

    destpath=$(fixpath "$(eval echo $FORMAT).$ext")
    destdir=$(dirname "$destpath")

    info "'$srcpath' -> '$BASEDIR/$destpath'"

    [ "$DRYRUN" ] && return

    mkdir -p "$BASEDIR/$destdir" || die
    cp "$srcpath" "$BASEDIR/$destpath" || die
}

install_flac () {
    $METAFLAC --export-tags-to=- "$1" | grep '^[[:alnum:]]*=' | install_file "$1" flac
}

parse_mp3_tags () {
    $ID3V2 -R "$1" | while IFS=': ' read tag value; do
        case "$tag" in
            TIT?)
                echo "TITLE=$value"
                ;;
            TALB) 
                echo "ALBUM=$value" 
                ;;
            TPE?)
                echo "ARTIST=$value"
                ;;
            TYER)
                echo "DATE=$value"
                ;;
            TRCK)
                echo "TRACKNUMBER=${value%%/*}"
                ;;
            TCON)
                echo "GENRE=${value%%(*}"
                ;;
            *)
                debug "Ignoring tag '$tag': $value"
                ;;
        esac
    done
}

install_mp3 () {
    parse_mp3_tags "$1" | install_file "$1" mp3
}

install_zip () {
    mkdir -p "$TMPDIR" || die
    unzip -q -d "$TMPDIR" "$1" || die
    find "$TMPDIR" -type f | while read filename; do
        basename=$(basename "$filename")
        filetype=$(tolower "${basename##*.}")

        if type "install_$filetype" > /dev/null; then
            install_$filetype "$filename" || die
        else
            warn "$filename: Unknown file type"
        fi
    done
    rm -rf "$TMPDIR" || die
}

# usage information
usage=$(cat <<EOF
Usage: $PROGRAM [OPTION]... FILE...
Execute command on each FILE.

  -c COMMAND  execute COMMAND [$command]
  -h          print this message and exit
  -o FILE     write to FILE instead of standard output
  -v          produce more verbose output

Examples:
  $PROGRAM *.sh             Check syntax of shell scripts
  $PROGRAM -c "cmp f" *     Compare all files to f
EOF
)

# parse command line options
while getopts ":a:A:c:d:f:hnp:s:t:vV" opt; do
    case $opt in 
        a)
            ARTIST="$OPTARG"
            ;;
        A)
            ALBUM="$OPTARG"
            ;;
	c) 
            [ -e "$OPTARG" ] || die "$OPTARG: No such file"
            . "$OPTARG"
            ;;
        d)
            BASEDIR="$OPTARG"
            ;;
        f)
            FORMAT="$OPARG"
            ;;
        h) 
            echo "$usage"
            exit
            ;;
        n)
            DRYRUN=1
            ;;
        p)
            PADDING="$OPTARG"
            ;;
        s)
            STARTNUMBER="$OPTARG"
            ;;
        t)
            TITLE="$OPTARG"
            ;;
        v)
            VERBOSE=$((VERBOSE + 1))
            ;;
        V)
            ARTIST="$VARIOUS"
            ;;
        *) 
            die "$usage"
            ;;
    esac
done

shift $(($OPTIND - 1))

# check for required arguments
[ $# -ne 0 ] || die "$usage"

# execute command on each file
for filename; do
    [ -f "$filename" ] || die "$filename: No such file"

    basename=$(basename "$filename")
    filetype=$(tolower "${basename##*.}")

    if type "install_$filetype" > /dev/null; then
        install_$filetype "$filename"
    else
        warn "$filename: Unknown file type"
    fi
done

exit 0
