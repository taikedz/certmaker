### Edit host config Usage:edit
#
#	certmaker edit HOST
#
# Edit the SSL config for the registered host
#
###/doc

cm:edit() {
	cm:helpcheck edit "$@"

    if [[ "$1" = --ca ]]; then
        cm:util:edit "$castore/authority.cnf"
    else
        cm:edit:host "$@"
    fi
}

cm:edit:host() {

	local myhost myhostd
	myhost="$1"; shift
	myhostd="$hoststore/$myhost"

	[[ -d "$myhostd" ]] || out:fail "Host '$myhost' does not exist."

    cm:util:edit "$myhostd/$myhost.cnf"
}
