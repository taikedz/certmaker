# CertMaker

A tool to create an OpenSSL certificate authority, and generate certificates, for use on internal networks.

This tool is intended as a security admin tool, and assumes by default that the entity creating the CA and managing the certs can deploy them.

It can optionally be used by site owners to generate their own keys and CSRs, to send along, and for CAs to sign ad-hoc CSRs.

## Install certmaker

	sudo ./install.sh

Initialize the config - the recommended path is `/etc/certmaker`, but you can also create a config in the local directory instead. `certmaker` looks for a `certmaker.config` file in turn in `./`, `~/.config/certmaker`, and `/etc/certmaker/`. Only the first one found is loaded.

	echo "castore=/var/certmaker/ca" > /etc/certmaker/certmaker.config
	echo "hoststore=/var/certmaker/hosts" >> /etc/certmaker/certmaker.config
	echo "keysize=4096" >> /etc/certmaker/certmaker.config
	echo "hashalgorithm=sha256" >> /etc/certmaker/certmaker.config

## Quick start

This section assumes tha the CA takes responsibility for creating and distributing key/certificate pairs.

### New CA

Initialize a new CA store

	certmaker temp ca

	certmaker new ca authority.cnf

When the CA certificate needs to be re-created, you can simply archive the existing CA, and create a new one

	certmaker renew ca

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

	certmaker temp host myhost.cnf

	# Edit the ./myhost.cnf file that is created
	
	certmaker regen-csr ./myhost.cnf

This will create a CSR file `myhost.csr` to send to the CA

### Ceritifate Authority

Follow the steps above for creating a CA

On receipt of a CSR, simply use the `sign csr` mode:

	certmaker sign csr CSRFILE

This will generate a certificate file to send back to the requestor.
