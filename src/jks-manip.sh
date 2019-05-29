#!/usr/bin/env bash

#%include std/out.sh
#%include std/bincheck.sh
#%include std/args.sh

set -euo pipefail

### JKS manipulator Usage:jksm
#Manipulate a Java Key Store or PKCS12 store using 'keytool' (which has too many options to remember for infrequent use ...)
#
#There are typically 3 options to the jks subcommand:
#
#-k KEYSTORE : the keystore to operate on
#-a ALIAS : the alias to use for the operation, where appropriate
#-f TARGETFILE : the file that will be read from or written to, changing depending on the command
#
#
#certmaker jks generate -k KEYSTORE -a ALIAS
#
#    Create a new key store, with a key alias
#
#
#certmaker jks csr -k KEYSTORE -a ALIAS -f CSRFILE
#
#    Derive a CSR from the KEYSTORE from the ALIAS entry
#
#
#certmaker jks add-ca -k KEYSTORE -a ALIAS -f CACERT
#
#    Add a CA certificate file CACERT to the KEYSTORE under ALIAS
#
#
#certmaker jks add-cert -k KEYSTORE -a ALIAS -f CERT
#
#    Add a certificate file CERT to the KEYSTORE under ALIAS
#
#
#certmaker jks add-key -k KEYSTORE -a ALIAS -f KEYFILE
#
#    Add a key file KEYFILE to the KEYSTORE under ALIAS
#
#    The key file must be either in PEM or PKCS12 format
#    If in PEM format, a similarly named CER file must accompany it
#
#    e.g. "import/application.key" needs a corresponding "import/application.cer" file
#
#
#certmaker jks delete -k KEYSTORE -a ALIAS
#
#    Delete an alias ALIAS from the KEYSTORE
#
#
#certmaker jks view -k KEYSTORE [-a ALIAS]
#
#    View the contents of the keystore, or optionally the contents under the keystore alias
#
#certmaker jks rename -k KEYSTORE -a OLDALIAS:NEWALIAS
#
#    Rename an old alias to a new one by cloning the old to new, and deleting the old one.
###/doc

jks:dispatch() {
    action="$1"; shift

    case "$action" in
        generate)
            jks:gen ;;

        csr)
            jks:csr ;;

        add-ca)
            jks:add:cacert ;;

        add-cert)
            jks:add:cert ;;

        add-key)
            jks:add:key ;;

        delete)
            jks:delete ;;

        view)
            jks:view ;;
        rename)
            jks:rename ;;

        *)
            out:fail "Unknown action '$action'" ;;
    esac
}

jks:args() {
    local flag

    for flag in "$@"
    do
        case "$flag" in
        -k)
            keystore="$(args:get -k "${SCRIPT_ARGS[@]}")"
            ;;
        -f)
            targetfile="$(args:get -f "${SCRIPT_ARGS[@]}")"
            ;;
        -a)
            ksalias="$(args:get -a "${SCRIPT_ARGS[@]}")"
            ;;

        esac
    done
}

jks:convert_key() {
    local certfile="${targetfile%.*}.cer"
    [[ -f "$certfile" ]] || out:fail "You must provide the certificate file as $certfile"
    out:info "Combining $targetfile and $certfile"

    # FIXME this generates error "unable to write 'random state'" even though output/result looks fine...
    openssl pkcs12 -export -inkey "$targetfile" -in "$certfile"
}

jks:gen() {
    jks:args -k || out:fail "Keystore is required"
    jks:args -f || :

    if [[ -z "${targetfile:-}" ]]; then
        jks:args -a || out:fail "Alias is required"
        keytool -genkey -alias "$ksalias" -keyalg RSA -keystore "$keystore" -deststoretype pkcs12 # FIXME This is still generateing JKS store??
    else
        jks:convert_key > "$keystore" # provided through $targetfile
    fi

}

jks:csr() {
    jks:args -k -a -f || out:fail "Keystore, Alias and Output CSR file are required"
    keytool -certreq -keyalg RSA -alias "$ksalias" -keystore "$keystore" -file "$targetfile"
}

jks:add:cacert() {
    jks:args -k -a -f || out:fail "Keystore, Alias and CA cert are required"
    keytool -import -alias "$ksalias" -keystore "$keystore" -trustcacerts -file "$targetfile"
}

jks:add:cert() {
    jks:args -k -a -f || out:fail "Keystore, Alias and Cert are required"
    keytool -import -alias "$ksalias" -keystore "$keystore" -file "$targetfile"
}

jks:ensure_pkcs12() {
    if [[ "$targetfile" =~ \.*\.p12 ]]; then
        cat "$targetfile"

    elif grep -qP "PRIVATE KEY" "$targetfile"; then
        out:warn "You provided PEM files - we will create a temporary store in which to put the key and certificate"
        jks:convert_key

        out:warn "You will be asked for the destination store password (your keystore) and the source store password (the intermediate store) to complete the import."
    else
        out:fail "PEM or PKCS12 file required!"
    fi
}

jks:cleanup() {
    if [[ -f "${p12datafile:-}" ]]; then
        rm "$p12datafile"
    fi
}

jks:add:key() {
    # Annoyingly, keytool needs a PKCS12 store for importing - it can't simply add a key
    jks:args -k -f || out:fail "Keystore and Key file ({.key + .cer} or .p12) are required"

    trap jks:cleanup EXIT

    p12datafile="$(mktemp XXXX.p12)"
    jks:ensure_pkcs12 > "$p12datafile" # Should fail on its own here if bad file

    keytool -importkeystore -srckeystore "$p12datafile" -destkeystore "$keystore" -srcstoretype pkcs12

    jks:cleanup
}

jks:delete() {
    jks:args -k -a || out:fail "Keystore and Alias are required"
    keytool -delete -alias "$ksalias" -keystore "$keystore"
}

jks:view() {
    jks:args -k || out:fail "Keystore is required"
    jks:args -a || :
    if [[ -n "${ksalias:-}" ]]; then
        keytool -list -alias "$ksalias" -keystore "$keystore"

    else
        keytool -list -keystore "$keystore"
    fi
}

jks:rename() {
    jks:args -k -a || out:fail "Keystore required ; Alias required as \`oldalias:newalias\`"

    local oldalias="${ksalias%:*}"
    local newalias="${ksalias#*:}"

    out:warn "We'll clone the old alias to a new name, then delete the old alias."
    ( set -ex
        keytool -keyclone -alias "$oldalias" -dest "$newalias" -keystore "$keystore"
        keytool -delete -alias "$oldalias" -keystore "$keystore"
    )
}

jksm:main() {
    if [[ -z "$*" ]] || [[ "$*" =~ --help ]]; then
        autohelp:print jksm
        exit
    fi

    bincheck:has keytool || out:fail "'keytool' is not installed - try installing openjdk-8-jre-headless"
    bincheck:has openssl || out:warn "'openssl' is not installed - key conversions will fail"

    SCRIPT_ARGS=("$@")
    jks:dispatch "$@"
}
