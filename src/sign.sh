#%include colours.sh askuser.sh
#%include files.sh util.sh

### CSR Signing Usage:sign
#
# Sign a known host or csr
#
# 	certmaker sign host HOSTNAME
#
# 	certmaker sign csr CSRFILE
#
###/doc

cm:sign() {
	cm:helpcheck sign "$@"
	
	local target="${1:-}"; shift || out:fail "Specify target to sign"

    if [[ -f "$target" ]]; then
		cm:sign:csr "$target" "$@"
    else
		cm:sign:host "$target" "$@"
    fi
}

cm:sign:csr() {
	local csrfile certfile opssl_opts passfile passin
	csrfile="$1"; shift
	certfile="${csrfile%.*}.cer"

	cm:sign:overwrite_check "$certfile"

	files:ensure_file "$castore/index.txt"
	files:ensure_file "$castore/serial.txt" '01'

    passfile="$castore/pass.txt"

    opssl_opts=( -config "$castore/authority.cnf" -policy signing_policy -extensions signing_req -out "$certfile" -infiles "$csrfile")

	# Switch to batch mode when password file exists
    if [[ -f "$passfile" ]]; then
        :: openssl ca -batch -passin "file:$passfile" "${opssl_opts[@]}"
    else
        :: openssl ca "${opssl_opts[@]}"
    fi
}

cm:sign:host() {
    local host_name hostd
    host_name="$1"; shift
    hostd="$hoststore/$host_name"

    [[ -d "$hostd" ]] || out:fail "No such host profile '$host_name'"

    cm:sign:csr "$hostd/$host_name.csr" "$hostd/$host_name.cer"
}

cm:sign:overwrite_check() {
	local certfile="$1"; shift
	
	[[ -f "$certfile" ]] || return 0

	askuser:confirm "${CYEL}Overwrite '$certfile'?$CDEF" || out:fail "Abort."

	rm "$certfile" || out:fail "Could not remove '$certfile'"
}
