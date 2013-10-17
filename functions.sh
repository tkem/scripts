#
# functions.sh - common shell script utility functions
#
# Copyright (C) 2012 Thomas Kemmer <tkemmer@computer.org>
#

#
# Usage: die [ARGUMENT]...
#
# Print ARGUMENT(s) to standard error and exit with status of last
# command if non-zero, 127 otherwise.
#
die () {
    local status=$?

    [ $# -eq 0 ] || echo "$@" >&2

    if [ $status -ne 0 ]; then
        exit $status
    else
        exit 127
    fi
}

#
# Usage: warn [ARGUMENT]...
#
# Print ARGUMENT(s) to standard error and return status of last
# command if non-zero, 127 otherwise.
#
warn () {
    local status=$?

    [ $# -eq 0 ] || echo "$@" >&2

    if [ $status -ne 0 ]; then
        return $status
    else
        return 127
    fi
}

#
# Usage: prompt MESSAGE [DEFAULT]
#
# Print MESSAGE to standard error and read a line from standard input;
# echo input (or DEFAULT, if input is null) to standard output.
#
prompt () {
    local input status

    echo -n "$1" >&2
    read input || status=$?
    echo ${input:-$2}

    return $status
}

#
# Usage: confirm MESSAGE [PATTERN]
#
# Print MESSAGE to standard error and read a line from standard input;
# return zero if input matches PATTERN (or "[Yy]*", if PATTERN is
# null), non-zero otherwise.
#
confirm () {
    local input pattern
    pattern=${2:-"[Yy]*"}
    
    echo -n "$1" >&2
    read input || return $?

    case $input in
        $pattern) 
            return 0;;
        *)
            return 1;;
    esac
}

#
# Usage: getpass MESSAGE
#
# Turn off echoing and control characters if standard input is a
# terminal; print MESSAGE to standard error, read one line of input
# (the "password"), echo password to standard output, and restore the
# terminal state.
#
getpass () {
    local input status stty

    stty=$(stty -g 2> /dev/null)
    [ "$stty" ] && stty -echo -isig

    echo -n "$1" >&2
    read input || status=$?
    echo $input

    if [ "$stty" ]; then
        stty $stty
        echo >&2
    fi

    return $status
}
