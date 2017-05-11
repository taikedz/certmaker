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

#%include bashout.sh autohelp.sh

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
