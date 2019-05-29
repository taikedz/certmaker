#!/bin/bash

set -euo pipefail

### Generate DNS Suffixes Usage:help
#
# This script generates the subjectAlternate keys for a multi-host certificate.
#
# Specify the service names to generate DNS alt strings for on the command line
#
#   generate-dns-alts.sh OPTIONS
#
# OPTIONS
#
# -f,--suffixes SUFFIXCSV
#   A comma-separated string of suffix values
#
# -b,--subdomains SUBDOMAINCSV
#   A comma-separated string of subdomain values
#
# -c,--config FILE
#   A config file, can be used instead of specifying -f and -b options
#
# Example:
#
#   generate-dns-alts.sh -b www,store -f .example.com,.domain.tld
#
# CONFIG
#
# A config file specified using the -c option allows specifying two keys, `suffixes` and `subdomains`
#
# Command line arguments will override the contents of this file
#
# Example:
#
#   subdomains=www,store
#   suffixes=.example.com,.domain.tld
#
###/doc

#%include std/autohelp.sh
#%include std/config.sh
#%include std/out.sh
#%include std/args.sh
#%include std/strings.sh

DNSALTS_config=""
DNSALTS_suffixes=""
DNSALTS_subdomains=""

load_config() {
    local settingname settingref

    if [[ -n "$DNSALTS_config" ]]; then
        config:declare DNSALTS "$DNSALTS_config"
        [[ -n "$DNSALTS_suffixes" ]] || DNSALTS_suffixes="$(config:read DNSALTS suffixes)"
        [[ -n "$DNSALTS_subdomains" ]] || DNSALTS_subdomains="$(config:read DNSALTS subdomains)"
    fi
}

parse_arguments() {
    debug:print "Parse args [$*]"
    local argdef=(
        "s:DNSALTS_suffixes:-f,--suffixes"
        "s:DNSALTS_subdomains:-b,--subdomain"
        "s:DNSALTS_config:-c,--config"
        "b:DEBUG_mode:--debug"
    )

    args:parse argdef - "$@"
}

validate_options() {
    debug:print "Validating options..."
    [[ -n "$DNSALTS_suffixes" ]] || out:fail "No suffixes specified"
    [[ -n "$DNSALTS_subdomains" ]] || out:fail "No subdomains specified"
}

split_options() {
    debug:print "Splitting DNSALTS suffixes and subdomains"
    strings:split DNSALTS_suffixes , "$DNSALTS_suffixes"
    strings:split DNSALTS_subdomains , "$DNSALTS_subdomains"

    debug:print "SUF: ${DNSALTS_suffixes[@]}"
    debug:print "SUB: ${DNSALTS_subdomains[@]}"
}

main() {
    autohelp:check "$@"

    parse_arguments "$@"
    load_config
    validate_options
    split_options

    local i=1

    for suf in "${DNSALTS_suffixes[@]}"; do
        for serv in "${DNSALTS_subdomains[@]}"; do
            echo "DNS.${i} = ${serv}${suf}"
            i=$((i+1))
        done
    done
}

main "$@"
