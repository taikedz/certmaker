### Certificate Getter Usage:cert-getter
#
# Certificate fetch and view agent.
#
#     certmaker fetch [SCHEME://]DOMAIN[:PORT]
#     certmaker view CERTFILE
#
# Fetch the certificate for a HTTPS domain to a file, or view the contents of a certificate file
#
# DOMAIN is the domain name to check, by default on port 443
#
# You can specify an alternative port, for example
#
#     certmaker fetch mydomain.net:8443
#
###/doc

#%include out.sh autohelp.sh

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

cert-getter:main() {
    cm:helpcheck cert-getter "$@"

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
