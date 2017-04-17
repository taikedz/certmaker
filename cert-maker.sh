#!/usr/bin/env bash

# Default number of days a certtificate should be valid for
defdays=365

action="$1"; shift

# ---- Generic helpers

function faile {
	local errcode="$1"

	if [[ "$errcode" =~ [0-9]+ ]]; then
		shift
	else
		errcode=1
	fi

	echo "--- $* ---" >&2
	exit "$errcode"
}

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

	openssl "x509" -days "$ndays" -in "$certname.csr" -signkey "$certname.key" -out "$certname.crt" || faile $? "Failed to create self-signed certificate"
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

if [[ "$*" =~ --help ]]; then
cat <<EOF

Certificate Generation and Signing Tool

COMMANDS
========

Create a CA root certificate (should only need to be done once per department) (specify a number of DAYS the certificate will be valid for)

	docert create-root-ca ca-name [DAYS]

Create a device/site certificate:

	docert create device-or-site-name

Sign a device's CSR to produce its approved certificate (specifying the number of DAYS the certificate should be valid for):

	docert sign ca-name device-or-site-name [DAYS] [OPTIONS ... ]

View a CSR's contents

	docert viewcsr CSRFILE

View a Certificate's contents

	docert viewcert CERTFILE

Check that a TARGETCERT was signed by a CACERT

	docert verify CACERT TARGETCERT

WORKFLOW
========

Root CA
-------

Your organisation should only have one Root CA (Certificate Authority). Use the `crete-root-ca` command in the creation of this one root certificate.

This will create threee files:

1. The Key file - keep this EXTREMELY safe. It is the lynchpin of your chain of trust and must by no means ever be provided by an unauthorized user.
	* Protect it with a password when the prompt appears during creation
	* Consider giving the key data to one operative, and the passphrase to another.

2. A CSR file - certifcate signing request.
	* A request file that says "please derive a certificate from me using someone's key"
	* Allows you to have you signed by an external authority, for example VeriSign, COMODO, etc
	* In this instance, it will be used for the self-signing, but being signed by a trusted thrid party instead is also valid
	* the combination of a CSR and a Key leads to the creation of a Certificate

3. The Certificate file - this is the public certificate that other programs and services will use to ascertain the validity of your identity.
	* This certificate will in this case also be the root certificate of your trust chain.
	* It guarantees that anything that is signed by your (super private) key is thus signed by you.


Device or Site Certificate
--------------------------

A device or website can be issued a certificate - it needs its own key, and its own CSR first. Use the `create` command to create a Key + CSR pair for said site or device.

Send the CSR file to the authority who is in control od the Root certificate for them to sign it. They will return a Certificate file for you.

Deploy the Key and the Certificate to the device or website as required.

The defaults for regular certificate creation is set up so that the issued certificate cannt be used for signing in turn.

Use the --allow-signing additional option enable it.

### Department CA

Any sub-organisation then can create their own key with which to sign certificates - they should do this with the `create` command.

They needs their CSR to be signed by the organisation's Root CA ; after which, they will be able to sign certificates themselves - unless the Root CA issues the certificate without the permission to sign against.

Signing a CSR
-------------

As a Certificate Authority (either as Root for the organisation, or as CA for your department), you can sign CSRs for sites and devices you have reponsibility for.

You need the CSR from the requestor, as well as your own Key and Certificate files,

You can then use the `sign` option on the Key, Certificate and requestor CSR to generate a sigfned certificate to return to the requestor.


EOF
exit 0
fi

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
