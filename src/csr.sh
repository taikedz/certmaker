#%include std/out.sh

#%include quick.sh

### certmaker csr NAME [FQDN ...] Usage:makecsr
# 
# Create a new CSR, generating a config and key file if necessary
#
###/doc

cm:csr() {
	local name

	cm:helpcheck makecsr "$@"

	name="${1:-}"; shift || out:fail "Specify the base name to create e.g. 'mysite'"

	[[ -f "$name.cnf" ]] || {
		[[ -n "$*" ]] || out:fail "Specify the websites to certify for (FQDNs, e.g. 'mysite.company.net')"

		cm:template host "$name.cnf"
		cm:quick:enumerate "$@" >> "$name.cnf"
		cm:util:edit "$name.cnf"
	}
	[[ -f "$name.key" ]] || cm:renew key "$name.cnf" "$name.key"
	
	cm:renew csr "$name.key" "$name.cnf" "$name.csr"
}
