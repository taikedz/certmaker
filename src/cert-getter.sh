#!/bin/bash

### Certificate Getter Usage:help
#
# Get the certificate of a site and install it to the trusted certs chain
#
# 	cert-getter.sh add DOMAIN
# 	cert-getter.sh view CERTFILE
#
# Add the certificate for a HTTPS domain, or view the contents of a certificate file
#
# DOMAIN is the domain name to check, by default on port 443
#
# You can specify an alternative port, for example
#
# 	cert-getter.sh add mydomain.net:8443
#
###/doc

#%include bashout.sh autohelp.sh

# Get a certificate for a site


function argcheck {
	local arg="$1"; shift

	if [[ -z "$1" ]]; then
		faile "Please specify $*"
	fi
}

function get_cert_info {
	openssl x509 -text -noout -in "$1"
}

function get_issuer_cert {
	local issuerline="$1"
	if [[ -z "$issuerline" ]]; then
		return
	fi
	: # example line -- CA Issuers - URI:http://cert.int-x3.letsencrypt.org/
	local CAURI="${issuerline#*URI:}"
	# May be able to get the CA name by grepping Issuer and finginf the CN= part
	local caname="$(echo "$CAURI"|md5sum)"
	local caname="ca-${caname:0:10}.crt" # Same CA, same filename

	# should we check for existing cert that has expired ?

	local bintemp=$(mktemp)
	wget -q -O "$bintemp" "$CAURI"
	openssl x509 -inform der -in "$bintemp" -out "$bintemp".pem

	sudo cp "$bintemp".pem "$domaindir/$caname"
}

action="$1"; shift
domain="$1"; shift

argcheck "$action" "action (view|add)"
argcheck "$domain" domain name

connectstring="$domain"
if [[ ! "$domain" =~ :[0-9]+$ ]]; then
	connectstring="$domain:443"
fi

domaindir=/usr/share/ca-certificates/domains

tmpcert="$(mktemp)"

openssl s_client -servername "$domain" -connect "$connectstring" </dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > "$tmpcert" || faile "Could not connect to [$domain]"

case "$action" in
add)
	sudo mkdir "$domaindir" -p
	sudo chmod 755 "$domaindir"
	sudo mv "$tmpcert" "$domaindir/$domain.crt"
	sudo chmod 644 "$domaindir/$domain.crt"

	get_issuer_cert "$(get_cert_info "$domaindir/$domain.crt"|grep 'CA Issuers - URI:')"

	sudo dpkg-reconfigure ca-certificates
	;;
view)
	get_cert_info "$tmpcert"
	;;
*)
	faile Invalid action
	;;
esac
