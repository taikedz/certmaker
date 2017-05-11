#!/usr/bin/env bash

### Certificate Generation and Signing Tool Usage:help
# 
# COMMANDS
# ========
# 
# Create a CA root certificate (should only need to be done once per department) (specify a number of DAYS the certificate will be valid for)
# 
# 	docert create-root-ca ca-name [DAYS]
# 
# 
# Create a device/site certificate:
# 
# 	docert create device-or-site-name
# 
# 
# Sign a device's CSR to produce its approved certificate (optionally specifying the number of DAYS the certificate should be valid for):
# 
# 	docert sign ca-name device-or-site-name [DAYS]
# 
# 
# View a CSR's contents
# 
# 	docert viewcsr CSRFILE
# 
# 
# View a Certificate's contents
# 
# 	docert viewcert CERTFILE
# 
# 
# Check that a TARGETCERT was signed by a CACERT
# 
# 	docert verify CACERT TARGETCERT
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

# Default number of days a certificate should be valid for
defdays=365

action="$1"; shift


function argcheck {
	local item="$1"; shift
	if [[ -z "$item" ]]; then
		faile 1 "No $* specified"
	fi
}

# --- Keygen activities

# Should simply generate a key
function generate_key {
	local certname="$1"; shift
	argcheck "$certname" certificate name

	[[ -f "$certname.key" ]] || openssl genrsa -out "$certname.key" 2048

}

# Should generate a CSR from a key fo the same name
function generate_csr {
	local certname="$1"; shift
	argcheck "$certname" certificate name

	[[ -f "$certname.csr" ]] || openssl req -new -key "$certname.key" -out "$certname.csr"
}

# --- Signing Activities

function self_sign_certificate {
	local certname="$1"; shift
	local ndays="$1"

	if [[ ! "$ndays" =~ [0-9]+ ]]; then
		ndays=$defdays
	else
		shift
	fi

	argcheck "$certname" certificate name

	openssl "x509" -req -days "$ndays" -in "$certname.csr" -signkey "$certname.key" -out "$certname.crt" || faile $? "Failed to create self-signed certificate"
}

function sign_certificate {
	local main_key="$1"; shift
	local subkey="$1"; shift

	local ndays="$1"
	if [[ ! "$ndays" =~ [0-9]+ ]]; then
		ndays=$defdays
	else
		shift
	fi

	argcheck "$main_key" signing key
	argcheck "$subkey" certificate name

	openssl "x509" -req -days "$ndays" -in "$subkey.csr" -CAkey "$main_key.key" -out "${subkey}-signed.crt" -CA "${main_key}.crt" -CAcreateserial || faile $? "Failed to sign certificate"
}

# --- Verification activities

function viewcert {
	argcheck "$1" Certificate file

	openssl x509 -text -noout -in "$1"
}

function viewcsr {
	argcheck "$1" CSR file

	openssl req -text -noout -verify -in "$1"
}

function verify_cert {
	local cacert="$1"
	local targetcert="$2"

	argcheck "$cacert" CA certificate
	argcheck "$targetcert" target certficate

	openssl verify -verbose -CAFile "$cacert" "$targetcert"
}

argcheck "$action" action

case "$action" in
	create-root-ca)

		generate_key "$1"
		generate_csr "$1"

		self_sign_certificate "$1" "$2"
		;;
	create)
		generate_key "$1"
		generate_csr "$1"
		;;
	self-sign)
		self_sign_certificate "$@"
		;;
	sign)
		sign_certificate "$@"
		;;
	viewcsr)
		viewcsr "$1"
		;;
	viewcert)
		viewcert "$1"
		;;
	verify)
		verify_cert "$1" "$2"
		;;
	genkey)
		generate_key "$@"
		;;
	gencsr)
		generate_csr "$@"
		;;
	*)
		faile 3 "Unrecognized command [$action]"
		;;
esac
