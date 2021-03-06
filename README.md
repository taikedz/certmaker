> Moved to <https://gitlab.com/taikedz/certmaker>

CertMaker
===========

A tool to create an OpenSSL certificate authority, and generate certificates, for use on internal networks.

The tool is written with three uses cases in mind:

* As an *internal* CA tool that will act as CA and manage certificate/key pairs centrally, distributing them to target servers
    * the `quick` command facilitates this workflow
* As a *CSR client* tool for generating CSRs to be sent to CAs
* As a plain internal CA that can sign individual CSRs

If you are deploying a public-facing web site, please consider using [Let's Encrypt](https://letsencrypt.org)


Quick Start
===========

Setup

    sudo ./install.sh

    # Adjust the ca_distinguished_name section
    sudo certmaker new ca

    # Adjust the host template's server_distinguished_name section
    sudo certmaker quick --edit

Create host key and certificate

    sudo certmaker quick new-host myhost.net

Renew host certificate, and create TGZ of asset files

    sudo certmaker quick new-host
    certmaker paths tgz new-host

Copy the assets to the target host.


Detailed walk-through
=====================


Install certmaker
-----------------

    sudo ./install.sh

Configuration is palced in `/etc/certmaker/certmaker.config`

If you do not install as root, it is placed in `~/.config/certmaker/certmaker.config`. Note that if a root installation already exists, you cannot install for a non-root user.

Ensure your `EDITOR` environment variable is set to your preferred text editor; if it is not set, CertMaker will try to use Emacs, nano, vim or vi.

New CA
---------

Sets up a new CA config, and opens an editor; specifically ensure you update the organisation country and details. You can also edit the `default_days` property to specify the number of days a newly signed certificate is valid for. You will be prompted for a password for the key.

    certmaker new ca

It is possible to save a password file in plaintext in `$CERTMAKERCONFIG/ca/pass.txt` to allow running in batch mode; treat this with caution as this means that your password will be lying in plain text on the filesystem.

If your CA is going to be used to centrally manage certificates and keys, set up a generic hosts config which will be used as a template for managed hosts

    certmaker quick --edit


Centrally managed hosts
-----------------------

If you want the CA to manage both keys and certificates for host machines, use these steps. In this scenario, the CA is responsible for creating both the keys and the certificates that will be placed on host machines.

Create a new host profile, specifying the domains to certify for - you will be prompted to edit it, and will then be given paths to a key and certificate file as a result.

    certmaker quick myhost DOMAIN ...

Re-run the command any time you want to renew the certificate. You will need to copy the new certificate to the desired host machine to replace the old certificate.

If you want to add new domains, you will need to edit the host config and add them manually, then re-generate the signed certificate:

    certmaker edit myhost
    certmaker quick myhost

Generic CSR and CA activities
-----------------------------

###    Target host

If you simply want to create a CSR for your web host, to send to a remote CA for signing:

	certmaker csr mysite mysite.company.net

This will create an OpenSSL config (annotated) and key, along with the corresponding CSR file `myhost.csr` to send to the CA


###    Certificate Authority

On receipt of a CSR, simply use the `sign csr` command:

    certmaker sign csr CSRFILE [OUTCERTFILE]

This will generate a certificate file as specified, or with the same base name as the CSR, to send back to the requestor.



Sub Commands
============


fetch/view - to retrieve and inspect certificates
-------------------------------------------------

###    `fetch`

You can fetch the certificate of a live site using

    certmaker fetch URL

Supported URLs include `https://`, `ldaps://`, `rdp://` and `ftps://`

URL can also be `$server:$port` e.g. `myserver.example.local:1234`

###    `view`

You can inspect the contents of a certificate PEM file (typically a block of base-64 data bounded with `BEGIN` and `END` statements) using

    certmaker view CERTFILE

Certificates generated by CertMaker are always PEM files.



jks - Java Keystore and PKCS12 store manipulation
-------------------------------------------------

You can manipulate a Java Key Store or PKCS12 key store using the `jks` subcommand.


When transferring a Key and Certificate pair to a Java target, you should hand off a PKCS12 file ratherm than PEM files

    certmaker jks generate -k generatedkeys.p12 -a defaultalias -f KEYFILE


You can then load the key into the Java host's keystore using

    certmaker jks add-key -k KEYSTORE -a ALIAS -f generatedkeys.p12


You can view a keystore contents using

    certmaker jks view -k KEYSTORE [-a ALIAS]

See `certmaker jks --help` for more info and commands.
