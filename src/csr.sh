#%include files.sh askuser.sh

### CSR Signing Usage:sign
#
# Sign a known host or csr
#
# 	certmaker sign host HOSTNAME
#
# 	certmaker sign csr CSRFILE
#
###/doc

cm:csr:sign() {
	cm:helpcheck sign "$@"
	
	local signtype="$1"

	case "$signtype" in
	host)
		cm:csr:sign-host "$@"
		;;
	csr)
		cm:csr:sign-csr "$@"
		;;
	*)
		out:fail "Unkown signing mode '$signtype'"
		;;
	esac
}

cm:csr:sign-csr() {
	local csrfile certfile
	csrfile="$1"; shift
	certfile="${csrfile%.*}.cer"

	cm:csr:overwrite_check "$certfile"

	files:ensure_file "$castore/index.txt"
	files:ensure_file "$castore/serial.txt" '01'

	# Try to use the password file *only* when in batch mode
	if [[ -n "$batchmode" ]]; then
		# Note - the strange syntax for `passin` further below in the command is ...
		#  ... well known. And looks butt-ugly.
		#  But needed.
		#  https://stackoverflow.com/questions/7577052/bash-empty-array-expansion-with-set-u
		local passfile="$castore/pass.txt"
		local passin=()
		if [[ -f "$passfile" ]]; then
			passin=(-passin "file:$passfile")
		fi
	fi

	:: openssl ca $batchmode ${passin[@]+"${passin[@]}"} -config "$castore/authority.cnf" -policy signing_policy -extensions signing_req -out "$certfile" -infiles "$csrfile"
}

cm:csr:sign-host() {
}

cm:csr:overwrite_check() {
	local certfile="$1"; shift
	
	[[ -f "$certfile" ]] || return 0

	askuser:confirm "Overwrite '$certfile'?" || out:fail "Abort."

	rm "$certfile" || out:fail "Could not remove '$certfile'"
}

### CSR Regenration Usage:csr-regen
#
#	certmaker regen-csr HOST
#
# Regenerate CSR for the host
#
###/doc
