#!/binbash

# Get a certificate for a site

function faile {
	echo "--- $* ---" >&2
	exit 1
}

function argcheck {
	local arg="$1"; shift

	if [[ -z "$1" ]]; then
		faile "Please specify $*"
	fi
}

domain="$1"; shift
argcheck "$domain" domain name

connectstring="$domain"
if [[ ! "$domain" =~ :[0-9]+$ ]]; then
	connectstring="$domain:443"
fi

domaindir=/usr/share/ca-certificates/domains

tmpcert="$(mktemp)"

openssl s_client -servername "$domain" -connect "$connectstring" </dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > "$tmpcert" || faile "Could not connect to [$domain]"

sudo mkdir "$domaindir" -p
sudo mv "$tmpcert" "$domaindir/$domain.crt"

sudo dpkg-reconfigure ca-certificates
