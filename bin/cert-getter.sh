#!/bin/bash

### Certificate Getter Usage:help
#
#     cert-getter.sh fetch [SCHEME://]DOMAIN[:PORT]
#     cert-getter.sh view CERTFILE
#
# Fetch the certificate for a HTTPS domain to a file, or view the contents of a certificate file
#
# DOMAIN is the domain name to check, by default on port 443
#
# You can specify an alternative port, for example
#
#     cert-getter.sh fetch mydomain.net:8443
#
###/doc

##bash-libs: out.sh @ 75ff4139 (1.1)

##bash-libs: colours.sh @ 75ff4139 (1.1)

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

##bash-libs: tty.sh @ 75ff4139 (1.1)

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

### Environment Variables Usage:bbuild
#
# MODE_DEBUG : set to 'true' to enable debugging output
# MODE_DEBUG_VERBOSE : set to 'true' to enable command echoing
#
###/doc

: ${MODE_DEBUG=false}
: ${MODE_DEBUG_VERBOSE=false}

# Internal
function out:buffer_initialize {
    OUTPUT_BUFFER_defer=(:)
}
out:buffer_initialize

### out:debug MESSAGE Usage:bbuild
# print a blue debug message to stderr
# only prints if MODE_DEBUG is set to "true"
###/doc
function out:debug {
    if [[ "$MODE_DEBUG" = true ]]; then
        echo "${CBBLU}DEBUG: $CBLU$*$CDEF" 1>&2
    fi
}

### out:debug:fork [MARKER] Usage:bbuild
#
# Pipe the data coming through stdin to stdout
#
# If debug mode is on, *also* write the same data to stderr, each line preceded by MARKER
#
# Insert this debug fork into pipes to see their output
#
###/doc
function out:debug:fork {
    if [[ "$MODE_DEBUG" = true ]]; then
        local MARKER="${1:-DEBUG: }"; shift || :

        cat - | sed -r "s/^/$MARKER/" | tee -a /dev/stderr
    else
        cat -
    fi
}

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

### out:dump Usage:bbuild
#
# Dump stdin contents to console stderr. Requires debug mode.
#
# Example
#
# 	action_command 2>&1 | out:dump
#
###/doc

function out:dump {
    echo -n "${CBPUR}$*" 1>&2
    echo -n "$CPUR" 1>&2
    cat - 1>&2
    echo -n "$CDEF" 1>&2
}

### out:break MESSAGE Usage:bbuild
#
# Add break points to a script
#
# Requires MODE_DEBUG set to true
#
# When the script runs, the message is printed with a propmt, and execution pauses.
#
# Press return to continue execution.
#
# Type `exit`, `quit` or `stop` to stop the program. If the breakpoint is in a subshell,
#  execution from after the subshell will be resumed.
#
###/doc

function out:break {
    [[ "$MODE_DEBUG" = true ]] || return 0

    echo -en "${CRED}BREAKPOINT: $* >$CDEF " >&2
    read
    if [[ "$REPLY" =~ quit|exit|stop ]]; then
        out:fail "ABORT"
    fi
}

if [[ "$MODE_DEBUG_VERBOSE" = true ]]; then
    set -x
fi
##bash-libs: autohelp.sh @ 75ff4139 (1.1)

### autohelp:print [ SECTION [FILE] ] Usage:bbuild
# Write your help as documentation comments in your script
#
# If you need to output the help from your script, or a file, call the
# `autohelp:print` function and it will print the help documentation
# in the current script to stdout
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
# You can set a different help section by specifying a subsection
#
# 	autohelp:print section2
#
# > This would print a section defined in this way:
#
# 	### Some title Usage:section2
# 	# <some content>
# 	###/doc
#
# You can set a different comment character by setting the 'HELPCHAR' environment variable:
#
# 	HELPCHAR=%
#
###/doc

HELPCHAR='#'

function autohelp:print {
    local SECTION_STRING="${1:-}"; shift || :
    local TARGETFILE="${1:-}"; shift || :
    [[ -n "$SECTION_STRING" ]] || SECTION_STRING=help
    [[ -n "$TARGETFILE" ]] || TARGETFILE="$0"

        echo -e "\n$(basename "$TARGETFILE")\n===\n"
        local SECSTART='^\s*'"$HELPCHAR$HELPCHAR$HELPCHAR"'\s+(.+?)\s+Usage:'"$SECTION_STRING"'\s*$'
        local SECEND='^\s*'"$HELPCHAR$HELPCHAR$HELPCHAR"'\s*/doc\s*$'
        local insec=false

        while read secline; do
                if [[ "$secline" =~ $SECSTART ]]; then
                        insec=true
                        echo -e "\n${BASH_REMATCH[1]}\n---\n"

                elif [[ "$insec" = true ]]; then
                        if [[ "$secline" =~ $SECEND ]]; then
                                insec=false
                        else
                echo "$secline" | sed -r "s/^\s*$HELPCHAR//g"
                        fi
                fi
        done < "$TARGETFILE"

        if [[ "$insec" = true ]]; then
                echo "WARNING: Non-terminated help block." 1>&2
        fi
    echo ""
}

### autohelp:paged Usage:bbuild
#
# Display the help in the pager defined in the PAGER environment variable
#
###/doc
function autohelp:paged {
    : ${PAGER=less}
    autohelp:print "$@" | $PAGER
}

### autohelp:check Usage:bbuild
#
# Automatically print help and exit if "--help" is detected in arguments
#
# Example use:
#
#    #!/bin/bash
#
#    ### Some help Usage:help
#    #
#    # Some help text
#    #
#    ###/doc
#
#    #%include autohelp.sh
#
#    main() {
#        autohelp:check "$@"
#
#        # now add your code
#    }
#
#    main "$@"
#
###/doc
autohelp:check() {
    if [[ "$*" =~ --help ]]; then
        cols="$(tput cols)"
        autohelp:print | fold -w "$cols" -s || autohelp:print
        exit 0
    fi
}

function argcheck {
    local arg="$1"; shift

    if [[ -z "$arg" ]]; then
        out:fail "Please specify $*"
    fi
}

function view_cert {
    [[ -f "$1" ]] || out:fail "No such file [$1]"
    openssl x509 -text -noout -in "$1"
}

function fetch_cert {
    local connectstring="$domain:$port"

    if [[ -f "$connectstring" ]]; then
        echo "$connectstring"
        return
    fi

    echo | (set -x ; openssl s_client -servername "$domain" -connect "$connectstring" ) | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > "$tmpcert" || out:fail "Could not connect to [$domain] on [$port]"
}

function determine_port_from_scheme {
    [[ -n "${scheme:-}" ]] || {
        port=443
        return 0
    }

    case "$scheme" in
    https)
        port=443 ;;
    ssh)
        port=22 ;;
    ldaps)
        port=636 ;;
    ftps)
        port=990 ;;
    *)
        out:fail "Cannot extrapolate port for $scheme" ;;
    esac
}

function get_port() {
    if [[ "$domain" =~ ^(.+?):([0-9]+)$ ]]; then
        port="${BASH_REMATCH[2]}"
        domain="${BASH_REMATCH[1]}"
    fi

    if [[ -z "${port:-}" ]]; then
        determine_port_from_scheme
    fi
}

function get_domain_and_scheme {
    domain="$target"
    [[ ! -f "$target" ]] || out:fail "[$target] is a file"

    # Blat scheme and path
    if [[ "$domain" =~ ^([a-zA-Z0-9]+):// ]]; then
        scheme="${BASH_REMATCH[1]}"
        domain="${domain#$scheme://}"
        domain="${domain%%/*}"
    fi
}

main() {
    autohelp:check "$@"

    local action="$1"; shift
    local target="$1"; shift

    argcheck "$action" "action (view|fetch)"
    argcheck "$target" "URL or cert file"

    case "$action" in
    fetch)
        get_domain_and_scheme
        get_port
        tmpcert="${domain}-fetched.cer"
        fetch_cert
        ;;
    view)
        view_cert "$target"
        ;;
    *)
        out:fail Invalid action
        ;;
    esac
}

main "$@"
