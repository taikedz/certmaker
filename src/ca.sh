#%include util.sh

### New Certificate Authority Usage:new-ca
#
# Create and manage a certificate authority
#
# 	certmaker new ca
#
# Ensure you have a `keysize` and `hashalgorithm` entry in your certmaker config
#
# If in doubt, use
#
# 	keysize=4096
# 	hashalgorithm=sha256
#
###/doc

cm:ca:new-ca() {
	cm:helpcheck new-ca "$@" .

	[[ ! -e "$castore" ]] || out:fail "'$castore' must not exist. Archive the existing directory, and try again."

	mkdir -p "$castore"
	chmod 700 "$castore"

	cm:template ca "$castore/authority.cnf"

    cm:util:edit "$castore/authority.cnf"

	:: openssl req -x509 -config "$castore/authority.cnf" -out "$castore/authority.cer" -outform PEM -keyout "$castore/authority.key" -newkey rsa:"$keysize" -"$hashalgorithm"

	out:info "You can store the certificate password in [$castore/pass.txt] for automatic signing"
}
