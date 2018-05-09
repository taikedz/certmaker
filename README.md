# CertMaker

A tool to create an OpenSSL certificate authority, and generate certificates, for use on internal networks.

This tool is intended as a security admin tool for internal websites, and assumes by default that the entity creating the CA and managing the certs can deploy them, in which case it should NOT be used for public websites.

It can optionally be used by site owners to generate their own keys and CSRs, to send along, and for CAs to sign ad-hoc CSRs. You can use this tool for generating your CSRs for sending to trusted and/or commercial CAs.

## Install certmaker

	sudo ./install.sh

Configuration is palced in `/etc/certmaker/certmaker.config`

If you do not install as root, it is placed in `~/.config/certmaker/certmaker.config`

## Quick start

### New CA

Get new CA config file. Edit the CNF file, specifically ensure you update the organisation country and details

	certmaker template ca authority.cnf

Now initialize a new store with that config

	certmaker new ca authority.cnf

    # You can delete the local cnf now
    # rm authority.cnf

### Centrally managed hosts

If you want the CA to manage both keys and certificates for host machines, use these steps. In this scenario, the CA is responsible for creating both the keys and the certificates that will be placed on host machines.


Create a new host profile ("host")

	certmaker new host myhost

Change host config, then generate key and CSR files

	certmaker edit myhost
	certmaker renew key myhost
	certmaker renew csr myhost

Sign the host's CSR

	certmaker sign host myhost

List the key and certificate paths, copy the files to your target host

	certmaker paths myhost

## Extra steps

To renew a certificate, just sign the existing host definition.

	certmaker sign host myhost

You will need to copy the new certificate to the desired host machine to replace the old certificate.

## Generic CSR and CA activities

### Target host

If you simply want to create a CSR for your machine, to send to a remote CA for signing:

On the target host to receive a certificate, create a CSR

	certmaker template host myhost.cnf

	# Edit the ./myhost.cnf file that is created

    # If you don't already have a key
    #certmaker renew key ./myhost.cnf
	
	certmaker renew csr ./key-file.key ./myhost.cnf

This will create a CSR file `myhost.csr` to send to the CA

### Certificate Authority

On receipt of a CSR, simply use the `sign csr` command:

	certmaker sign csr CSRFILE [CERTFILE]

This will generate a certificate file as specified, or with the same base name as the CSR, to send back to the requestor.
