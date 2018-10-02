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

##bash-libs: out.sh @ 40805f29 (after 1.1.6)

##bash-libs: colours.sh @ 40805f29 (after 1.1.6)

### Colours for bash Usage:bbuild
# A series of colour flags for use in outputs.
#
# Example:
# 	
# 	echo -e "${CRED}Some red text ${CBBLU} some blue text $CDEF some text in the terminal's default colour")
#
# Requires processing of escape characters.
#
# Colours available:
#
# CRED, CBRED, HLRED -- red, bold red, highlight red
# CGRN, CBGRN, HLGRN -- green, bold green, highlight green
# CYEL, CBYEL, HLYEL -- yellow, bold yellow, highlight yellow
# CBLU, CBBLU, HLBLU -- blue, bold blue, highlight blue
# CPUR, CBPUR, HLPUR -- purple, bold purple, highlight purple
# CTEA, CBTEA, HLTEA -- teal, bold teal, highlight teal
#
# CDEF -- switches to the terminal default
# CUNL -- add underline
#
# Note that highlight and underline must be applied or re-applied after specifying a colour.
#
# If the session is detected as being in a pipe, colours will be turned off.
#   You can override this by calling `colours:check --color=always` at the start of your script
#
###/doc

##bash-libs: tty.sh @ 40805f29 (after 1.1.6)

tty:is_ssh() {
    [[ -n "$SSH_TTY" ]] || [[ -n "$SSH_CLIENT" ]] || [[ "$SSH_CONNECTION" ]]
}

tty:is_pipe() {
    [[ ! -t 1 ]]
}

### colours:check ARGS Usage:bbuild
#
# Check the args to see if there's a `--color=always` or `--color=never`
#   and reload the colours appropriately
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

colours:auto() {
    if tty:is_pipe ; then
        COLOURS_ON=false
    else
        COLOURS_ON=true
    fi

    colours:define
    return 0
}

colours:define() {
    if [[ "$COLOURS_ON" = false ]]; then

        export CRED=''
        export CGRN=''
        export CYEL=''
        export CBLU=''
        export CPUR=''
        export CTEA=''

        export CBRED=''
        export CBGRN=''
        export CBYEL=''
        export CBBLU=''
        export CBPUR=''
        export CBTEA=''

        export HLRED=''
        export HLGRN=''
        export HLYEL=''
        export HLBLU=''
        export HLPUR=''
        export HLTEA=''

        export CDEF=''

    else

        export CRED=$(echo -e "\033[0;31m")
        export CGRN=$(echo -e "\033[0;32m")
        export CYEL=$(echo -e "\033[0;33m")
        export CBLU=$(echo -e "\033[0;34m")
        export CPUR=$(echo -e "\033[0;35m")
        export CTEA=$(echo -e "\033[0;36m")

        export CBRED=$(echo -e "\033[1;31m")
        export CBGRN=$(echo -e "\033[1;32m")
        export CBYEL=$(echo -e "\033[1;33m")
        export CBBLU=$(echo -e "\033[1;34m")
        export CBPUR=$(echo -e "\033[1;35m")
        export CBTEA=$(echo -e "\033[1;36m")

        export HLRED=$(echo -e "\033[41m")
        export HLGRN=$(echo -e "\033[42m")
        export HLYEL=$(echo -e "\033[43m")
        export HLBLU=$(echo -e "\033[44m")
        export HLPUR=$(echo -e "\033[45m")
        export HLTEA=$(echo -e "\033[46m")

        export CDEF=$(echo -e "\033[0m")

    fi
}

colours:auto

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

##bash-libs: autohelp.sh @ 40805f29 (after 1.1.6)

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
##bash-libs: readkv.sh @ 40805f29 (after 1.1.6)

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

### readkv:moeaningful_data FILE Usage:bbuild
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
