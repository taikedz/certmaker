### Quick mode Usage:quick
#
# Set up a base configuration for host certificates; don't add any `DNS.*` entries yet
#
#    certmaker quick --edit
#
# Once you have a base configuration, you can create any number of individual hosts
#
#   certmaker quick PROFILENAME DOMAINS ...
#
# The profile name is a name for the store of the config, key, CSR and certificate files.
#
# DOMAINS ... is only required when first creating the profile ; to subsequently edit the domains the certificate will certify for, run
#
#   certmaker edit PROFILENAME
#
#
###/doc

cm:quick() {
    cm:helpcheck quick "$@"

    if [[ "$1" = "--edit" ]]; then
        cm:quick:edit_template

    else
        cm:quick:host "$@"
    fi
}

cm:quick:edit_template() {
    local quick_template
    quick_template="$hoststore/quick.cnf"
    if [[ ! -f "$quick_template" ]]; then
        cm:template host "$quick_template"
    fi

    cm:util:edit "$quick_template"
}

cm:quick:host() {
    local host_name
    host_name="${1:-}"; shift || out:fail "Specify a host name"

    cm:quick:ensure_host "$host_name" "$@"

    cm:quick:ensure_key "$host_name"
    cm:renew:csr-host "$host_name"

    cm:sign:host "$host_name"

    # Echo the colour byte to stderr
    # but the keys to stdout
    # in case user is grepping for the files
    echo -n "$CBBLU" >&2
    echo "$(cm:paths:show "$host_name")"
    echo -n "$CDEF" >&2
}

cm:quick:ensure_host() {
    local host_name hostd hostconf quick_template x
    host_name="${1:-}"; shift
    hostd="$hoststore/$host_name"
    hostconf="$hostd/$host_name.cnf"

    quick_template="$hoststore/quick.cnf"
    [[ -f "$quick_template" ]] || out:fail "Quick template not yet set - run 'certmaker quick --edit' to create a global template first"

    if [[ ! -f "$hostconf" ]]; then

        askuser:confirm "Create host '$host_name' ?"
        [[ -n "$*" ]] || out:fail "You need to also specify domains to add."

        cm:host:new-host "$host_name"
        cp "$quick_template" "$hostconf"

        cm:quick:enumerate "$@" >> "$hostconf"

        cm:edit:host "$host_name"
    fi
}

cm:quick:enumerate() {
    for x in $(seq 1 $#); do
        echo "DNS.$x = $1"
        shift
    done
}

cm:quick:ensure_key() {
    local host_name hostd hostconf
    host_name="${1:-}"; shift
    hostd="$hoststore/$host_name"

    if [[ ! -f "$hostd/$host_name.key" ]]; then
        cm:renew:key-host "$host_name"
    fi
}

