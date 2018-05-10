### CSR Regenration Usage:renew
#
# (Re-)generate key for the host or config.
#
#	certmaker renew key CONFIG [KEYFILE]
#	certmaker renew key HOST
#
# (Re-)generate CSR for the host or key+config file pair
#
#	certmaker renew csr KEYFILE CONFIG [CSRFILE]
#	certmaker renew csr HOST
#
###/doc

cm:renew() {
    cm:helpcheck renew "$@"

    local rtype="${1:-}" ; shift || out:fail "Specify renewal type"
    local filehost="${1:-}" ; shift || out:fail "Specify target file or host"

    case "$rtype" in
    csr|key)
        if [[ -f "$filehost" ]]; then
            cm:renew:${rtype}-file "$filehost" "$@"
        else
            cm:renew:${rtype}-host "$filehost" "$@"
        fi
        ;;
    *)
        out:fail "Unknown renewal type '$rtype'"
        ;;
    esac
}

cm:renew:key-file() {
    local config keyfile

    config="${1:-}"; shift  || out:fail "Specify an OpenSSL config file"
    keyfile="${1:-}"; shift || {
        keyfile="${config%.*}.key"
    }

    :: openssl genrsa -out "$keyfile" "$keysize" -config "$config"
}

cm:renew:key-host() {
    local host_name hostd
    host_name="${1:-}" ; shift || out:fail "Specify a host profile name"

    hostd="$hoststore/$host_name"
    [[ -d "$hostd" ]] || out:fail "No such host profile [$host_name]"

    cm:renew:key-file "$hostd/${host_name}.cnf" "$hostd/${host_name}.key"
}

cm:renew:csr-file() {
    local keyfile csrfile config
    keyfile="${1:-}"; shift || out:fail "Specify an input key file"
    config="${1:-}"; shift  || out:fail "Specify an OpenSSL config file"

    csrfile="${1:-}"; shift || {
        csrfile="${keyfile%.*}.csr"
    }

    :: openssl req -new -key "$keyfile" -out "$csrfile" -config "$config"
}

cm:renew:csr-host() {
    local host_name hostd
    host_name="${1:-}" ; shift || out:fail "Specify a host profile name"

    hostd="$hoststore/$host_name"
    [[ -d "$hostd" ]] || out:fail "No such host profile [$host_name]"

    cm:renew:csr-file "$hostd/${host_name}.key" "$hostd/${host_name}.cnf" "$hostd/${host_name}.csr"
}
