#!/bin/bash
#
# https://github.com/andreax79/remember-command-output
#
# Copyright (c) 2016, Andrea Bonomi <andrea.bonomi@gmail.com>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
# SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
# OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
# CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

FILENAME=~/.ro

display_usage() {
    echo "Usage: $0 [-l] COMMAND [arg ...]"
    echo "       $0 [-l] RANGE [COMMAND arg ...]"
    echo
    echo "Options:"
    echo "  -l, --lines           Output the line number, starting at line 1"
    echo "  RANGE                 Comma-separated list of line number or ranges"
    echo
    echo "Examples:"
    echo
    echo "  Execute the grep command and store the output"
    echo "      $0 grep -r test ."
    echo
    echo "  Display the output of the last command, adding line numbers"
    echo "      $0 -l"
    echo
    echo "  Open the files at lines 2-4 and 5 in the output of the last command with vi"
    echo "      $0 2-4,5 vi"
    exit 2
}

is_option() {
    [[ $1 =~ ^\- ]]
    return $?
}

# Parse options
fields=1
non_option_argument=0
while [[ $# > 0 ]]; do
    key="$1"
    if [ $non_option_argument == 1 ] || ! is_option $key; then
        non_option_argument=1
        remains="$remains \"$1\""
    else
        case $key in
            -)
                remains="$remains \"$1\""
            ;;
            -l|--lines)
                show_line_numbers="yes"
            ;;
            -n|--line-number)
                fields="1,2"
            ;;
            -h|--help)
                display_usage
            ;;
            *)
                echo "$0: illegal option $key"
                exit 1
            ;;
        esac
    fi
    shift
done
eval set -- $remains

# If the first argument is not a line number or a range, it's a command to be executed :)
VALID='0-9\,\-'
if [[ ! $1 =~ ^\- ]] && [[ $1 =~ [^$VALID] ]]; then
    # Store the command output in FILENAME
    if [ "$show_line_numbers" = "yes" ]; then
        $@ | tee $FILENAME | nl
    else
        $@ | tee $FILENAME
    fi
    # Exit with the exit status of the command
    exit ${PIPESTATUS[0]}
fi

lines=$1
cmd=$2

if [ -z "$lines" -o "$lines" = "-" ]; then
    # No line number/range
    if [ "$cmd" ]; then
        files=$(cut -d ":" -f $fields $FILENAME)
        $cmd $files
    elif [ "$show_line_numbers" = "yes" ]; then
        nl $FILENAME
    else
        cat $FILENAME
    fi
else
    # Convert the line numbers/ranges for sed
    # e.g. 10-20,30 ==> -e 10,20p -e 30p
    lines=$1
    sed_arguments=()
    while IFS=',' read -ra ADDR; do
      for i in "${ADDR[@]}"; do
        sed_arguments+=(${i//[-]/,}p)
      done
    done <<< "$lines"
    sed_arguments="-n ${sed_arguments[@]/#/-e }"

    if [ "$cmd" ]; then
        files=$(sed $sed_arguments $FILENAME | cut -d ":" -f $fields)
        $cmd $files
        exit $?
    elif [ "$show_line_numbers" = "yes" ]; then
        nl $FILENAME | sed $sed_arguments
    else
        sed $sed_arguments $FILENAME
    fi
fi

