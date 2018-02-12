#!/bin/bash -eu

cd "$(dirname "$0")"
export PATH="../bin:$PATH"

# ========== FIRST STEP
# This demonstration should run on the test CA host

## ===============================================================
## ++++ Things to know

	your_ca_name="my-demo-ca"
	your_ca_pass="demo pass"

## ===============================================================
## ++++ Things you'll do

# Copy the required config and modify it to suit needs
cp ../ssl-conf/ca-example.cnf ca-demo.cnf
# `sed` is used here for test. Use a normal text editor for the real editing.
sed -r 's/countryName.+=\s*2.+/countryName = GB/' -i ca-demo.cnf

# You will be prompted for the password
echo -e "\nWhen prompted, use the following password:\n\n\t\033[33;1m${your_ca_pass}\033[0m\n" ; sleep 1

echo -ne "\033[44;31;1mYou run:\033[0m"
(set -x



	certtool create-ca --config=ca-demo.cnf --ca="$your_ca_name"



)

# Save the password (optional)
echo "$your_ca_pass" > "${your_ca_name}-store/pass.txt"

# ========== SECOND STEP
# This demonstration should run on the test domain host
#  (the one which needs a certificate)

## ===============================================================
## ++++ Things to know

	your_host_fqdn="my-site.domain.tld"

## ===============================================================
## ++++ Things you'll do

# Copy the required config and modify it to suit needs
cp ../ssl-conf/site-example.cnf site-demo.cnf
# Use a normal text editor when doing real work
sed -r 's/countryName.+=.+/countryName = GB/' -i site-demo.cnf

# Generate cert for new domain
echo -ne "\033[44;31;1mYou run:\033[0m"
(set -x


	certtool new-domain --config=site-demo.cnf --fqdn="$your_host_fqdn"


)

echo "Now send [${your_host_fqdn}.csr] to the certifciate authority"
#!/bin/bash -eu

# ========== THIRD STEP
# This demonstration should run on the test CA host

## ===============================================================
## ++++ Things to know

	your_ca_name="my-demo-ca"
	your_ca_pass="demo pass"
	your_csr_file="my-site.domain.tld.csr"

# This wil simply decide whether to use --batch during signing
#   can be useful for highly-automated items
non_interactive=yes

## ===============================================================
## ++++ Things you'll do

# Decide whether to use non-interactive:
case "$non_interactive" in
no)
	echo -e "Use the following password:\n\n\t\033[33;1m${your_ca_pass}\033[0m\n"
	echo -ne "\033[44;31;1mYou run:\033[0m"
	( set -x


		certtool sign --config=ca-demo.cnf --ca="$your_ca_name" --csr="$your_csr_file"
	
	
	)
	;;
yes)
	if [[ ! -f "${your_ca_name}-store/pass.txt" ]]; then
		echo -e "Use the following password:\n\n\t\033[33;1m${your_ca_pass}\033[0m\n"
	fi
	echo -ne "\033[44;31;1mYou run:\033[0m"
	( set -x


		certtool sign --config=ca-demo.cnf --ca="$your_ca_name" --csr="$your_csr_file" --batch
	
	
	)
	;;
*)
	echo "Non interactive should be 'yes' or 'no'."
	;;
esac

echo -e "\n\033[33;1mThe new certificate is in '${your_csr_file%.*}-signed.cer' , the CA certificate is in '${your_ca_name}-store/${your_ca_name}-ca.cer'" \
	"\n\nYou will need to provide both to your web site\n\n\033[0m"

mkdir -p demo-outputs
mv ca-demo.cnf site-demo.cnf my-* demo-outputs/
