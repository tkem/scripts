#!/bin/sh
#
# itracks.sh - copy media files to locations based on meta tags
#
# Copyright (C) 2013 Thomas Kemmer <tkemmer@computer.org>
#

# uncomment to exit if untested command fails
#set -e

# uncomment to trace commands
#set -x

# Vorbis comment tags [http://www.xiph.org/vorbis/doc/v-comment.html]
#
# TITLE: Track/Work name
#
# VERSION: The version field may be used to differentiate multiple
# versions of the same track title in a single collection. (e.g. remix
# info)
#
# ALBUM: The collection name to which this track belongs
#
# TRACKNUMBER: The track number of this piece if part of a specific
# larger collection or album
#
# ARTIST: The artist generally considered responsible for the work. In
# popular music this is usually the performing band or singer. For
# classical music it would be the composer. For an audio book it would
# be the author of the original text.
#
# PERFORMER: The artist(s) who performed the work. In classical music
# this would be the conductor, orchestra, soloists. In an audio book
# it would be the actor who did the reading. In popular music this is
# typically the same as the ARTIST and is omitted.
#
# COPYRIGHT: Copyright attribution, e.g., '2001 Nobody's Band' or
# '1999 Jack Moffitt'
#
# LICENSE: License information, eg, 'All Rights Reserved', 'Any Use
# Permitted', a URL to a license such as a Creative Commons license
# ("www.creativecommons.org/blahblah/license.html") or the EFF Open
# Audio License ('distributed under the terms of the Open Audio
# License. see http://www.eff.org/IP/Open_licenses/eff_oal.html for
# details'), etc.
#
# ORGANIZATION: Name of the organization producing the track (i.e. the
# 'record label')
#
# DESCRIPTION: A short text description of the contents
#
# GENRE: A short text indication of music genre
#
# DATE: Date the track was recorded
#
# LOCATION: Location where track was recorded
#
# CONTACT: Contact information for the creators or distributors of the
# track. This could be a URL, an email address, the physical address
# of the producing label.
#
# ISRC: ISRC number for the track; see the ISRC intro page for more
# information on ISRC numbers.
#

# Tag mappings [http://minimserver.com/ug-library.html#Tag%20mappings]
#
# FLAC/Vorbis           ID3v2.2         ID3v2.3         ID3v2.4         iTunes
#                                
# ALBUM                 TAL             TALB            TALB            ©alb
# ALBUMARTIST           TP2             TPE2            TPE2            aART
# ALBUMARTISTSORT       TS2             TSO2            TSO2            soaa
# ALBUMSORT             TSA             TSOA            TSOA            soal
# ARTIST                TP1             TPE1            TPE1            ©ART
# ARTISTSORT            TSP             TSOP            TSOP            soar
# BPM                   TBP             TBPM            TBPM            tmpo
# COMMENT               COM             COMM            COMM            ©cmt
# COMPILATION           TCP             TCMP            TCMP            cpil
# COMPOSER              TCM             TCOM            TCOM            ©wrt
# COMPOSERSORT          TSC             TSOC            TSOC            soco
# CONDUCTOR             TP3             TPE3            TPE3             
# CONTENTGROUP          TT1             TIT1            TIT1            ©grp
# COPYRIGHT             TCR             TCOP            TCOP            cprt
# DATE                  TYE, TDA        TYER, TDAT      TDRC            ©day
# DISCNUMBER            TPA             TPOS            TPOS            disk
# DISCSUBTITLE                                          TSST                            
# ENCODEDBY             TEN             TENC            TENC            ©too
# GENRE                 TCO             TCON            TCON            gnre, ©gen
# ISRC                  TRC             TSRC            TSRC      
# LABEL                 TPB             TPUB            TPUB     
# LANGUAGE              TLA             TLAN            TLAN             
# LYRICIST              TXT             TEXT            TEXT             
# LYRICS                ULT             USLT            USLT            ©lyr
# MOOD                                                  TMOO     
# ORIGINALDATE          TOR             TORY            TDOR             
# RELEASEDATE                                           TDRL                            
# REMIXER               TP4             TPE4            TPE4     
# SUBTITLE              TT3             TIT3            TIT3     
# TITLE                 TT2             TIT2            TIT2            ©nam
# TITLESORT             TST             TSOT            TSOT            sonm
# TOTALDISCS            TPA             TPOS            TPOS            disk
# TOTALTRACKS           TRK             TRCK            TRCK            trkn
# TRACKNUMBER           TRK             TRCK            TRCK            trkn

PROGRAM=$(basename $0 .sh)

ID3V2=id3v2
METAFLAC=metaflac
MKTEMP=mktemp
UNZIP=unzip

OUTPUTDIR="$HOME/Music"
OUTPUTFORMAT='$ARTIST/$ALBUM/$TRACKNUMBER $TITLE'
TRACKPADDING=2

die () {
    status=$?
    [ $# -eq 0 ] || echo "$0:" "$@" >&2
    exit $(expr $status \| 1)
}

warn () {
    echo "$0:" "$@" >&2
}

info () {
    [ ${VERBOSE:=0} -ge 1 ] && echo "$0:" "$@" >&2
}

debug () {
    [ ${VERBOSE:=0} -ge 2 ] && echo "$0:" "$@" >&2
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

install_track () {
    while IFS='=' read tag value; do
        case $tag in
            TITLE|VERSION|ALBUM|ARTIST|PERFORMER|GENRE|DATE)
                eval $tag="\${$tag:=$(mungename $value)}"
                ;;
            TRACKNUMBER)
                # expr interprets numbers as decimal, even in case of leading 0s
                TRACKNUMBER=${TRACKNUMBER:=$(expr ${STARTNUMBER:-1} + $value - 1)}
                ;;
            *)
                debug "Skipping tag '$tag=$value'"
                ;;
        esac
    done

    if [ "$TRACKNUMBER" -a "$TRACKPADDING" ]; then
        TRACKNUMBER=$(printf "%0.${TRACKPADDING}d" $TRACKNUMBER)
    fi

    suffix="${1##*.}"
    destpath=$(fixpath "$(eval echo $OUTPUTFORMAT).$suffix")
    destdir=$(dirname "$destpath")

    if [ "$DRYRUN" ]; then
        echo "$destpath"
    else
        info "'$1' -> '$OUTPUTDIR/$destpath'"
        mkdir -p "$OUTPUTDIR/$destdir" || die
        cp "$srcpath" "$OUTPUTDIR/$destpath" || die
    fi
}

install_dir () {
    find "$1" -type f | while read filename; do
        filetype=$(tolower "${filename##*.}")

        if type "handle_$filetype" > /dev/null; then
            handle_$filetype "$filename" || die
        else
            warn "$filename: Unknown file type"
        fi
    done
}

handle_flac () {
    $METAFLAC --export-tags-to=- "$1" | grep '^[[:alnum:]]*=' | install_track "$1"
}

handle_mp3 () {
    $ID3V2 -R "$1" | grep '^[[:alnum:]]*:' | while IFS=': ' read tag value; do
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
                debug "$1: Skipping tag '$tag=$value'"
                ;;
        esac
    done | install_track "$1"
}

handle_zip () {
    ZIPDIR=$($MKTEMP -d -t "$(basename $0).XXXXXXXXXX") || die
    trap 'rm -rf "$ZIPDIR"' HUP INT PIPE TERM EXIT

    unzip -q -d "$ZIPDIR" "$1" || die
    install_dir "$ZIPDIR" || die
    rm -rf "$ZIPDIR" || die
}

usage () {
    cat <<EOF
Usage: $PROGRAM [OPTION]... FILE...
Copy media files to locations based on meta tags.

  -a ARTIST     override artist information
  -A ALBUM      override album information
  -c FILENAME   read configuration from file
  -d DIRECTORY  set output directory [$OUTPUTDIR]
  -l            only list generated file names, do not install
  -o FORMAT     set output format [$OUTPUTFORMAT]
  -p PADDING    set track number padding width [$TRACKPADDING]
  -r            handle directories recursively
  -s NUMBER     start numbering of tracks at NUMBER
  -t TITLE      override title information
  -v            produce more verbose output
EOF

    exit $1
}

# load system defaults
if [ -r /etc/$PROGRAM.conf ]; then
    . /etc/$PROGRAM.conf
fi

# load user preferences
if [ -r $HOME/.$PROGRAM ]; then
    . $HOME/.$PROGRAM
fi

# parse command line options
while getopts ":a:A:c:d:lo:p:rs:t:v" opt; do
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
            OUTPUTDIR="$OPTARG"
            ;;
        l)
            DRYRUN=1
            ;;
        o)
            OUTPUTFORMAT="$OPTARG"
            ;;
        p)
            TRACKPADDING="$OPTARG"
            ;;
        r)
            RECURSE=1
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
        *) 
            usage 1
            ;;
    esac
done

shift $(($OPTIND - 1))

# check for required arguments
[ $# -ne 0 ] || usage

for filename; do
    [ -e "$filename" ] || die "$filename: No such file"

    if [ -d "$filename" ]; then
        if [ "$RECURSE" ]; then
            install_dir "$filename"
        else
            warn "$filename: Skipping directory"
        fi
    else
        filetype=$(tolower "${filename##*.}")

        if type "handle_$filetype" > /dev/null; then
            handle_$filetype "$filename"
        else
            warn "$filename: Unknown file type"
        fi
    fi
done

exit 0
