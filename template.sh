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

# program name
PROGRAM="$(basename "$0")"

# err - write arguments to standard error and exit
err () {
    echo "$PROGRAM:" "$@" >&2
    exit 1
}

# log - write arguments to standard error if $VERBOSE is not null
log () {
    if [ "$VERBOSE" ]; then
        echo "$PROGRAM:" "$@" >&2
    fi
}

# default settings
command="sh -n"

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
while getopts ":c:ho:v" opt; do
    case $opt in 
        c)
            command="$OPTARG"
            ;;
        h) 
            echo "$usage"
            exit
            ;;
        o)
            # redirect standard output
            exec > "$OPTARG"
            ;;
        v)
            VERBOSE=1
            ;;
        *) 
            err "$usage"
            ;;
    esac
done

shift $(($OPTIND - 1))

# check for required arguments
[ $# -ne 0 ] || err "$usage"

# execute command on each file
for file; do
    [ -f "$file" ] || err "$file: No such file"
    log "$command $file"
    $command "$file"
done

exit 0
