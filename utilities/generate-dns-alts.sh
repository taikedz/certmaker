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

#%include autohelp.sh
#%include readkv.sh
#%include out.sh

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
