# CertMaker.sh

A comand line tool for creating and managing certificate signing.

Executables can be found in `bin/`

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


Known Issues
============

* regular certificate CSR requests ability to sign CRLs in turn

