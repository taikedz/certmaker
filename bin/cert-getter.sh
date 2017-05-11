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

#!/bin/bash

#!/bin/bash

### Colours for bash Usage:bbuild
# A series of colour flags for use in outputs.
#
# Example:
# 	
# 	echo "${CRED}Some red text ${CBBLU} some blue text $CDEF some text in the terminal's default colour"
#
# Colours available:
#
# CDEF -- switches to the terminal default
#
# CRED, CBRED -- red and bright/bold red
# CGRN, CBGRN -- green and bright/bold green
# CYEL, CBYEL -- yellow and bright/bold yellow
# CBLU, CBBLU -- blue and bright/bold blue
# CPUR, CBPUR -- purple and bright/bold purple
#
###/doc

export CDEF="[0m"
export CRED="[31m"
export CGRN="[32m"
export CYEL="[33m"
export CBLU="[34m"
export CPUR="[35m"
export CBRED="[1;31m"
export CBGRN="[1;32m"
export CBYEL="[1;33m"
export CBBLU="[1;34m"
export CBPUR="[1;35m"

MODE_DEBUG=no

### debuge MESSAGE Usage:bbuild
# print a blue debug message to stderr
# only prints if MODE_DEBUG is set to "yes"
###/doc
function debuge {
	if [[ "$MODE_DEBUG" = yes ]]; then
		echo -e "${CBBLU}DEBUG:$CBLU$*$CDEF" 1>&2
	fi
}

### infoe MESSAGE Usage:bbuild
# print a green informational message to stderr
###/doc
function infoe {
	echo -e "$CGRN$*$CDEF" 1>&2
}

### warne MESSAGE Usage:bbuild
# print a yellow warning message to stderr
###/doc
function warne {
	echo -e "${CBYEL}WARN:$CYEL $*$CDEF" 1>&2
}

### faile [CODE] MESSAGE Usage:bbuild
# print a red failure message to stderr and exit with CODE
# CODE must be a number
# if no code is specified, error code 127 is used
###/doc
function faile {
	local ERCODE=127
	local numpat='^[0-9]+$'

	if [[ "$1" =~ $numpat ]]; then
		ERCODE="$1"; shift
	fi

	echo "${CBRED}ERROR FAIL:$CRED$*$CDEF" 1>&2
	exit $ERCODE
}

function dumpe {
	echo -n "[1;35m$*" 1>&2
	echo -n "[0;35m" 1>&2
	cat - 1>&2
	echo -n "[0m" 1>&2
}

function breake {
	if [[ "$MODE_DEBUG" != yes ]]; then
		return
	fi

	read -p "${CRED}BREAKPOINT: $* >$CDEF " >&2
	if [[ "$REPLY" =~ $(echo 'quit|exit|stop') ]]; then
		faile "ABORT"
	fi
}

### Auto debug Usage:main
# When included, bashout processes a special "--debug" flag
#
# It does not remove the debug flag from arguments.
###/doc

if [[ "$*" =~ --debug ]]; then
	MODE_DEBUG=yes
fi
#!/bin/bash

### printhelp Usage:bbuild
# Write your help as documentation comments in your script
#
# If you need to output the help from a running script, call the
# `printhelp` function and it will print the help documentation
# in the current script to stdout
#
# A help comment looks like this:
#
#	### <title> Usage:help
#	#
#	# <some content>
#	#
#	# end with "###/doc" on its own line (whitespaces before
#	# and after are OK)
#	#
#	###/doc
#
###/doc

CHAR='#'

function printhelp {
	local USAGESTRING=help
	local TARGETFILE=$0
	if [[ -n "$*" ]]; then USAGESTRING="$1" ; shift; fi
	if [[ -n "$*" ]]; then TARGETFILE="$1" ; shift; fi

        echo -e "\n$(basename "$TARGETFILE")\n===\n"
        local SECSTART='^\s*'"$CHAR$CHAR$CHAR"'\s+(.+?)\s+Usage:'"$USAGESTRING"'\s*$'
        local SECEND='^\s*'"$CHAR$CHAR$CHAR"'\s*/doc\s*$'
        local insec="$(mktemp --tmpdir)"; rm "$insec"
        cat "$TARGETFILE" | while read secline; do
                if [[ "$secline" =~ $SECSTART ]]; then
                        touch "$insec"
                        echo -e "\n${BASH_REMATCH[1]}\n---\n"
                elif [[ -f $insec ]]; then
                        if [[ "$secline" =~ $SECEND ]]; then
                                rm "$insec"
                        else
				echo "$secline" | sed -r "s/^\s*$CHAR//g"
                        fi
                fi
        done
        if [[ -f "$insec" ]]; then
                echo "WARNING: Non-terminated help block." 1>&2
		rm "$insec"
        fi
	echo ""
}

### automatic help Usage:main
#
# automatically call help if "--help" is detected in arguments
#
###/doc
if [[ "$@" =~ --help ]]; then
	printhelp
	exit 0
fi

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
