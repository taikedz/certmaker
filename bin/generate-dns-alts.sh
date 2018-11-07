#!/bin/bash

set -euo pipefail

### Generate DNS Suffixes Usage:help
#
# This script generates the subjectAlternate keys for a multi-host certificate.
#
#   generate-dns-alts.sh [ SUBDOMAIN ... ] [ -- SUFFIX ...]
#
# Specify the service names to generate DNS alt strings for on the command line
#
# Example:
#
#   generate-dns-alts.sh www store -- .example.com .domain.tld
#
# CONFIG
#
# A config file in the working directory `dns-alts.conf` allows specifying two keys, `suffixes` and `subdomains`
#
# Command line arguments will override the contents of this file
#
# Example:
#
#   subdomains = www store
#   suffixes = .example.com .domain.tld
#
###/doc

##bash-libs: tty.sh @ bf310b32 (1.4.1)

tty:is_ssh() {
    [[ -n "$SSH_TTY" ]] || [[ -n "$SSH_CLIENT" ]] || [[ "$SSH_CONNECTION" ]]
}

tty:is_pipe() {
    [[ ! -t 1 ]]
}

##bash-libs: colours.sh @ bf310b32 (1.4.1)

### Colours for terminal Usage:bbuild
# A series of shorthand colour flags for use in outputs, and functions to set your own flags.
#
# Not all terminals support all colours or modifiers.
#
# Example:
# 	
# 	echo "${CRED}Some red text ${CBBLU} some blue text. $CDEF Some text in the terminal's default colour")
#
# Preconfigured colours available:
#
# CRED, CBRED, HLRED -- red, bright red, highlight red
# CGRN, CBGRN, HLGRN -- green, bright green, highlight green
# CYEL, CBYEL, HLYEL -- yellow, bright yellow, highlight yellow
# CBLU, CBBLU, HLBLU -- blue, bright blue, highlight blue
# CPUR, CBPUR, HLPUR -- purple, bright purple, highlight purple
# CTEA, CBTEA, HLTEA -- teal, bright teal, highlight teal
# CBLA, CBBLA, HLBLA -- black, bright red, highlight red
# CWHI, CBWHI, HLWHI -- white, bright red, highlight red
#
# Modifiers available:
#
# CBON - activate bright
# CDON - activate dim
# ULON - activate underline
# RVON - activate reverse (switch foreground and background)
# SKON - activate strikethrough
# 
# Resets available:
#
# CNORM -- turn off bright or dim, without affecting other modifiers
# ULOFF -- turn off highlighting
# RVOFF -- turn off inverse
# SKOFF -- turn off strikethrough
# HLOFF -- turn off highlight
#
# CDEF -- turn off all colours and modifiers(switches to the terminal default)
#
# Note that highlight and underline must be applied or re-applied after specifying a colour.
#
# If the session is detected as being in a pipe, colours will be turned off.
#   You can override this by calling `colours:check --color=always` at the start of your script
#
###/doc

### colours:check ARGS ... Usage:bbuild
#
# Check the args to see if there's a `--color=always` or `--color=never`
#   and reload the colours appropriately
#
#   main() {
#       colours:check "$@"
#
#       echo "${CGRN}Green only in tty or if --colours=always !${CDEF}"
#   }
#
#   main "$@"
#
###/doc
colours:check() {
    if [[ "$*" =~ --color=always ]]; then
        COLOURS_ON=true
    elif [[ "$*" =~ --color=never ]]; then
        COLOURS_ON=false
    fi

    colours:define
    return 0
}

### colours:set CODE Usage:bbuild
# Set an explicit colour code - e.g.
#
#   echo "$(colours:set "33;2")Dim yellow text${CDEF}"
#
# See SGR Colours definitions
#   <https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters>
###/doc
colours:set() {
    # We use `echo -e` here rather than directly embedding a binary character
    if [[ "$COLOURS_ON" = false ]]; then
        return 0
    else
        echo -e "\033[${1}m"
    fi
}

colours:define() {

    # Shorthand colours

    export CBLA="$(colours:set "30")"
    export CRED="$(colours:set "31")"
    export CGRN="$(colours:set "32")"
    export CYEL="$(colours:set "33")"
    export CBLU="$(colours:set "34")"
    export CPUR="$(colours:set "35")"
    export CTEA="$(colours:set "36")"
    export CWHI="$(colours:set "37")"

    export CBBLA="$(colours:set "1;30")"
    export CBRED="$(colours:set "1;31")"
    export CBGRN="$(colours:set "1;32")"
    export CBYEL="$(colours:set "1;33")"
    export CBBLU="$(colours:set "1;34")"
    export CBPUR="$(colours:set "1;35")"
    export CBTEA="$(colours:set "1;36")"
    export CBWHI="$(colours:set "1;37")"

    export HLBLA="$(colours:set "40")"
    export HLRED="$(colours:set "41")"
    export HLGRN="$(colours:set "42")"
    export HLYEL="$(colours:set "43")"
    export HLBLU="$(colours:set "44")"
    export HLPUR="$(colours:set "45")"
    export HLTEA="$(colours:set "46")"
    export HLWHI="$(colours:set "47")"

    # Modifiers
    
    export CBON="$(colours:set "1")"
    export CDON="$(colours:set "2")"
    export ULON="$(colours:set "4")"
    export RVON="$(colours:set "7")"
    export SKON="$(colours:set "9")"

    # Resets

    export CBNRM="$(colours:set "22")"
    export HLOFF="$(colours:set "49")"
    export ULOFF="$(colours:set "24")"
    export RVOFF="$(colours:set "27")"
    export SKOFF="$(colours:set "29")"

    export CDEF="$(colours:set "0")"

}

colours:auto() {
    if tty:is_pipe ; then
        COLOURS_ON=false
    else
        COLOURS_ON=true
    fi

    colours:define
    return 0
}

colours:auto

##bash-libs: out.sh @ bf310b32 (1.4.1)

### Console output handlers Usage:bbuild
#
# Write data to console stderr using colouring
#
###/doc

### out:info MESSAGE Usage:bbuild
# print a green informational message to stderr
###/doc
function out:info {
    echo "$CGRN$*$CDEF" 1>&2
}

### out:warn MESSAGE Usage:bbuild
# print a yellow warning message to stderr
###/doc
function out:warn {
    echo "${CBYEL}WARN: $CYEL$*$CDEF" 1>&2
}

### out:defer MESSAGE Usage:bbuild
# Store a message in the output buffer for later use
###/doc
function out:defer {
    OUTPUT_BUFFER_defer[${#OUTPUT_BUFFER_defer[@]}]="$*"
}

# Internal
function out:buffer_initialize {
    OUTPUT_BUFFER_defer=(:)
}
out:buffer_initialize

### out:flush HANDLER ... Usage:bbuild
#
# Pass the output buffer to the command defined by HANDLER
# and empty the buffer
#
# Examples:
#
# 	out:flush echo -e
#
# 	out:flush out:warn
#
# (escaped newlines are added in the buffer, so `-e` option is
#  needed to process the escape sequences)
#
###/doc
function out:flush {
    [[ -n "$*" ]] || out:fail "Did not provide a command for buffered output\n\n${OUTPUT_BUFFER_defer[*]}"

    [[ "${#OUTPUT_BUFFER_defer[@]}" -gt 1 ]] || return 0

    for buffer_line in "${OUTPUT_BUFFER_defer[@]:1}"; do
        "$@" "$buffer_line"
    done

    out:buffer_initialize
}

### out:fail [CODE] MESSAGE Usage:bbuild
# print a red failure message to stderr and exit with CODE
# CODE must be a number
# if no code is specified, error code 127 is used
###/doc
function out:fail {
    local ERCODE=127
    local numpat='^[0-9]+$'

    if [[ "$1" =~ $numpat ]]; then
        ERCODE="$1"; shift || :
    fi

    echo "${CBRED}ERROR FAIL: $CRED$*$CDEF" 1>&2
    exit $ERCODE
}

### out:error MESSAGE Usage:bbuild
# print a red error message to stderr
#
# unlike out:fail, does not cause script exit
###/doc
function out:error {
    echo "${CBRED}ERROR: ${CRED}$*$CDEF" 1>&2
}

##bash-libs: autohelp.sh @ bf310b32 (1.4.1)

### Autohelp Usage:bbuild
#
# Autohelp provides some simple facilities for defining help as comments in your code.
# It provides several functions for printing specially formatted comment sections.
#
# Write your help as documentation comments in your script
#
# To output a named section from your script, or a file, call the
# `autohelp:print` function and it will print the help documentation
# in the current script, or specified file, to stdout
#
# A help comment looks like this:
#
#    ### <title> Usage:help
#    #
#    # <some content>
#    #
#    # end with "###/doc" on its own line (whitespaces before
#    # and after are OK)
#    #
#    ###/doc
#
# It can then be printed from the same script by simply calling
#
#   autohelp:print
#
# You can print a different section by specifying a different name
#
# 	autohelp:print section2
#
# > This would print a section defined in this way:
#
# 	### Some title Usage:section2
# 	# <some content>
# 	###/doc
#
# You can set a different comment character by setting the 'HELPCHAR' environment variable.
# Typically, you might want to print comments you set in a INI config file, for example
#
# 	HELPCHAR=";" autohelp:print help config-file.ini
# 
# Which would then find comments defined like this in `config-file.ini`:
#
#   ;;; Main config Usage:help
#   ; Help comments in a config file
#   ; may start with a different comment character
#   ;;;/doc
#
#
#
# Example usage in a multi-function script:
#
#   #!/bin/bash
#
#   ### Main help Usage:help
#   # The main help
#   ###/doc
#
#   ### Feature One Usage:feature_1
#   # Help text for the first feature
#   ###/doc
#
#   feature1() {
#       autohelp:check_section feature_1 "$@"
#       echo "Feature I"
#   }
#
#   ### Feature Two Usage:feature_2
#   # Help text for the second feature
#   ###/doc
#
#   feature2() {
#       autohelp:check_section feature_2 "$@"
#       echo "Feature II"
#   }
#
#   main() {
#       if [[ -z "$*" ]]; then
#           ### No command specified Usage:no-command
#           #No command specified. Try running with `--help`
#           ###/doc
#
#           autohelp:print no-command
#           exit 1
#       fi
#
#       case "$1" in
#       feature1|feature2)
#           "$1" "$@"            # Pass the global script arguments through
#           ;;
#       *)
#           autohelp:check "$@"  # Check if main help was asked for, if so, exits
#
#           # Main help not requested, return error
#           echo "Unknown feature"
#           exit 1
#           ;;
#       esac
#   }
#
#   main "$@"
#
###/doc

### autohelp:print [ SECTION [FILE] ] Usage:bbuild
# Print the specified section, in the specified file.
#
# If no file is specified, prints for current script file.
# If no section is specified, defaults to "help"
###/doc

HELPCHAR='#'

autohelp:print() {
    local input_line
    local section_string="${1:-}"; shift || :
    local target_file="${1:-}"; shift || :
    [[ -n "$section_string" ]] || section_string=help
    [[ -n "$target_file" ]] || target_file="$0"

    #echo -e "\n$(basename "$target_file")\n===\n"
    local sec_start='^\s*'"$HELPCHAR$HELPCHAR$HELPCHAR"'\s+(.+?)\s+Usage:'"$section_string"'\s*$'
    local sec_end='^\s*'"$HELPCHAR$HELPCHAR$HELPCHAR"'\s*/doc\s*$'
    local in_section=false

    while read input_line; do
        if [[ "$input_line" =~ $sec_start ]]; then
            in_section=true
            echo -e "\n${BASH_REMATCH[1]}\n======="

        elif [[ "$in_section" = true ]]; then
            if [[ "$input_line" =~ $sec_end ]]; then
                in_section=false
            else
                echo "$input_line" | sed -r "s/^\s*$HELPCHAR/ /;s/^  (\S)/\1/"
            fi
        fi
    done < "$target_file"

    if [[ "$in_section" = true ]]; then
            out:fail "Non-terminated help block."
    fi
}

### autohelp:paged Usage:bbuild
#
# Display the help in the pager defined in the PAGER environment variable
#
###/doc
autohelp:paged() {
    : ${PAGER=less}
    autohelp:print "$@" | $PAGER
}

### autohelp:check ARGS ... Usage:bbuild
#
# Automatically print "help" sections and exit, if "--help" is detected in arguments
#
###/doc
autohelp:check() {
    autohelp:check_section "help" "$@"
}

### autohelp:check_section SECTION ARGS ... Usage:bbuild
# Automatically print documentation for named section and exit, if "--help" is detected in arguments
#
###/doc
autohelp:check_section() {
    local section arg
    section="${1:-}"; shift || out:fail "No help section specified"

    for arg in "$@"; do
        if [[ "$arg" =~ --help ]]; then
            cols="$(tput cols)"
            autohelp:print "$section" | fold -w "$cols" -s || autohelp:print "$section"
            exit 0
        fi
    done
}
##bash-libs: readkv.sh @ bf310b32 (1.4.1)

### Key Value Pair Reader Usage:bbuild
#
# Read a value given the key, from a specified file
#
###/doc

### readkv KEY FILE [DEFAULT] Usage:bbuild
#
# The KEY is the key in the file. A key is identified as starting at the beginning of a line, and ending at the first '=' character
#
# The value starts immediately after the first '=' character.
#
# If no value is found, the DEFAULT value is returned, or an empty string
#
###/doc

function readkv {
    local thedefault thekey thefile
    thekey="$1" ; shift
    thefile="$1"; shift

    if [[ -n "${1:-}" ]]; then
        thedefault="$1"; shift || :
    fi

    local res="$(readkv:meaningful_data "$thefile"|grep -E "^$thekey"'\s*='|sed -r "s/^$thekey"'\s*=\s*//')"
    if [[ -z "$res" ]]; then
        echo "${thedefault:-}"
    else
        echo "$res"
    fi
}

### readkv:require KEY FILE Usage:bbuild
#
# Like readkv, but causes a failure if the file does not exist.
#
###/doc

function readkv:require {
    if [[ -z "${2:-}" ]]; then
        out:fail "No file specified to read [$*]"
    fi

    if [[ ! -f "$2" ]] ; then
        out:fail "No such file $2 !"
    fi

    if ! head -n 1 "$2" > /dev/null; then
        out:fail "Could not read $2"
    fi
    readkv "$@"
}

### readkv:meaningful_data FILE Usage:bbuild
# Dump the file contents, stripping meaningless data (empty lines and comment lines)
###/doc
readkv:meaningful_data() {
    grep -v -P '^\s*(#.*)?$' "$1"
}

DNSALTS_config="dns-alts.conf"
DNSALTS_suffixes=(:)
DNSALTS_subdomains=(:)

get_subdomains() {
    local load_from_file=false

    if [[ -n "$*" ]]; then
        while [[ -n "${1:-}" ]] && [[ "$1" != -- ]]; do
            DNSALTS_subdomains+=("$1")
            shift
        done
    fi

    [[ -n "${DNSALTS_subdomains[@]:1}" ]] || load_from_file=true

        
    if [[ "$load_from_file" = true ]] && [[ -f "$DNSALTS_config" ]]; then
        DNSALTS_subdomains+=($(readkv:require subdomains "$DNSALTS_config"))
    fi

    [[ -n "${DNSALTS_subdomains[@]:1}" ]] || out:fail "No subdomains specified."
}

get_suffixes() {
    local load_from_file=false
    if [[ -n "$*" ]]; then
        while [[ -n "${1:-}" ]] && [[ "$1" != -- ]]; do
            shift
        done
        shift || load_from_file=true # final token "--"
    fi

    [[ -n "$*" ]] || load_from_file=true
        
    if [[ "$load_from_file" = true ]] && [[ -f "$DNSALTS_config" ]]; then
        DNSALTS_suffixes+=($(readkv:require suffixes "$DNSALTS_config"))
    else
        while [[ -n "${1:-}" ]]; do
            DNSALTS_suffixes+=("$1")
            shift
        done
    fi

    [[ -n "${DNSALTS_suffixes[@]:1}" ]] || out:fail "No suffixes specified."
}

main() {
    autohelp:check "$@"

    get_suffixes "$@"
    get_subdomains "$@"

    local i=1

    for serv in "${DNSALTS_subdomains[@]:1}"; do
        for suf in "${DNSALTS_suffixes[@]:1}"; do
            echo "DNS.${i} = ${serv}${suf}"
            i=$((i+1))
        done
    done
}

main "$@"
