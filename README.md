# CertMaker

A tool to create an OpenSSL certificate authority, and generate certificates, for use on internal networks.

This tool is intended as a security admin tool, and assumes by default that the entity creating the CA and managing the certs can deploy them.

It can optionally be used by site owners to generate their own keys and CSRs, to send along, and for CAs to sign ad-hoc CSRs.

## Install certmaker

	sudo ./install.sh

Configuration is palced in `/etc/certmaker/certmaker.config`

If you do not install as root, it is placed in `~/.config/certmaker/certmaker.config`

## Quick start

This section assumes that the CA takes responsibility for creating and distributing key/certificate pairs.

### New CA

Initialize a new CA store

	certmaker template ca authority.cnf

	certmaker new ca authority.cnf

### New hosts

Create a new host

	certmaker new host myhost

Sign the host's CSR

	certmaker sign host myhost

List the key and certificate paths, copy the files to your target host

	certmaker paths myhost

## Extra steps

Change host config, and regenerate CSR

	certmaker edit myhost
	certmaker renew csr myhost

To renew a certificate, just sign the existing host definition, and copy the new certificate to the target host machine.

	certmaker sign myhost

## Generic CSR and CA activities

### Target host

On the target host to receive a certificate, create a CSR

	certmaker template host myhost.cnf

	# Edit the ./myhost.cnf file that is created
	
	certmaker renew csr ./myhost.cnf

This will create a CSR file `myhost.csr` to send to the CA

### Certificate Authority

Follow the steps above for creating a CA

On receipt of a CSR, simply use the `sign csr` mode:

	certmaker sign csr CSRFILE

This will generate a certificate file to send back to the requestor.
