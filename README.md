# CertMaker

A comand line tool for creating and managing certificate signing for internal network usage.

This project aims to simplfy the certificate generation and signing workflow down as much as possible. The project relies on `bash` and `openssl`, and uses some `bash-builder` components. It was written and tested against Ubuntu 16.04, but should work on any GNU/Linux that has GNU coreutils.

If you are wanting to create certificates for public web sites and servers, do not use this project, use [https://letsencrypt.org/](https://letsencrypt.org/)

Eventually I hope to allow it to act as an internal alternative for Let's Encrypt, which can only certify public servers.

## When to use CA ?

You will use the CA instructions if you are setting up the Certificate Authority:

* You are likely to be in the IT department of your company
* or you work in the delpoyment team of your department

If you do not have authority to say what root CAs to trust in your company or department, you are probably not going to be setting up a CA.

If you are setting up a new internal web server/application, you probably just want the CSR section

## When to use CSR ?

If you are setting up a web server that needs a HTTPS connection, the you would want to generate a Key and CSR pair

You can then send the CSR file to your CA controller for signing ; they will return a certificate for you to use in your web application (Apache, Nginx, Tomcat, etc)

# Quick Start

Install CertMaker's `certtool` - you will want to do this on the CA host and on the web site host

	sudo cp bin/certtool /usr/bin/certtool

## Set up a Certificate Authority Host

This only happens once, when initially setting up a CA

Copy `ssl-conf/ca-example.cnf` to a desirable location, edit it, and generate the CA key and cert
	
	mkdir -p ~/CertMaker-data
	cp ssl-conf/ca-example.cnf ~/CertMaker-data/ca-data.cnf
	cd ~/CertMaker-data
	
	# now edit your ca-data.cnf file
	# and change the data in the "ca_distinguished_name" section
	# e.g.
	#   nano ca-data.cnf
	#
	# then create the CA:
	
	certtool create-ca --conf=ca-data.cnf --ca=YOUR_CA_NAME

You will now have a file `your-ca-name-store/YOUR_CA_NAME-ca.cer` - this is your CA root certificate. Distribute this to your client computers and applications as required. Your IT department can deploy this via Domain policy.

**DO NOT distribute any of the rest of the data.** See below discussion about Root CAs.

## Get a certificate for your internal web site

	# On the web server you want to give a certificate to
	
	mkdir -p /etc/apache2/certs
	cp ssl-conf/site-example.cnf /etc/apache2/certs/sitename.cnf
	cd /etc/apache2/certs

	
	# now edit your sitename.cnf file
	# and change the data in the "server_distinguished_name" section
	# e.g.
	#     nano sitename.cnf
	#
	# then create the key and CSR
	
	certtool new-domain --conf=sitename.cnf --fqdn=your.domain.name


This will create two files, `your.domain.name.key` and `your.domain.name.csr`

Copy the CSR file to the CA host, or send it to the person controlling the Certificate Authority

## Use the CA to sign the CSR

As the controller of the CA, you can now sign any CSRs that are sent to you

	cd ~/CertMaker-data
	certtool --conf=ca-data.cnf" --ca="YOUR_CA_NAME" --csr="/path/to/the/request/file.csr" --batch

This will create a file `/path/to/the/request/file-signed.cer`

You can send this CER certificate file back to the requestor. If you have a certificate chain file (not yet implemented), send that back along with the certificate.

## View certificate data

You can view the certificate data with the `bin/cert-getter.sh` tool

You can fetch a certificate from an arbitrary url - for example

	bin/cert-getter.sh fetch https://google.com

You can view the certificate data from a local PEM certificate file

	bin/cert-getter.sh view cert-file.cer

# About SSL Certificates and Certificate Authorities / workflows

This section is a geenral overview of how Public-key cryptography works, and considerations for the Certificate Authority.

For more detailed information, see [Public-key cryptography on Wikipedia](https://en.wikipedia.org/wiki/Public-key_cryptography)

## Root CA

Your organisation or department should only have one Root CA (Certificate Authority). Use the `certtool create-ca ...` command in the creation of this one root certificate.

This involves a number of important files, most notable of which:

1. The Key file - keep this EXTREMELY safe. It is the lynchpin of your chain of trust and must by no means ever be provided by an unauthorized user.
	* NOBODY other than the person controlling the CA should have access to this
	* How you protect it is up to you, but typically, high levels of security and "paranoia" are usual.
	* If an untrusted/unknown person has access to this this key, they can masquerade as you
		* depending on what level of guarantees your key identity is meant to server, this can range from mildly inconvenient to catastrophic to a business as a whole.

2. The Certificate file - this is the public certificate that other programs and services will use to ascertain the validity of your identity.
	* This certificate will in this case also be the root certificate of your trust chain.
	* It guarantees that anything that is signed by your (super private) key is thus signed by you.


## Device or Site Certificate

Additional to a Key and Certificate, a third file is typically involved for certificates that are signed bya a Root CA:

* A CSR file - certifcate signing request.
	* A request file that says "please derive a certificate from me to confirm someone's key"
	* Allows you to have your key's identity signed by an external authority, for example VeriSign, COMODO, etc
	* In this instance, it will be used for the self-signing, but being signed by a trusted thrid party instead is also valid
	* the combination of a CSR and a Key leads to the creation of a Certificate

A device or website can be issued a certificate - it needs its own key, and its own CSR first. Use the `certtool new-domain ...` command to create a Key + CSR pair for said site or device.

Send the CSR file to the authority who is in control od the Root certificate for them to sign it. They will return a Certificate file for you.

Deploy the site's Key and the Signed Certificate received to the device or website as required.

### Department CA

Any sub-organisation then can create their own key with which to sign certificates - they should do this with the `create` command.

They need their CSR to be signed by the organisation's Root CA ; after which, they will be able to sign certificates themselves - unless the Root CA issues the certificate without the permission to sign against.

## Signing a CSR

As a Certificate Authority (either as Root for the organisation, or as CA for your department), you can sign CSRs for sites and devices you have reponsibility for.

You need the CSR from the requestor, as well as your own Key and Certificate files,

You can then use the `sign` option on the Key, Certificate and requestor CSR to generate a sigfned certificate to return to the requestor.


