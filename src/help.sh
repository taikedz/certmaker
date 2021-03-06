
### certmaker Usage:help
#
# Tool to generate a CA, generate keys and CSRs, and sign CSRs
#
# From https://github.com/taikedz/CertMaker
#
# Further below are /all/ the available commands, but you probably only want one of the following:
#
#   certmaker new ca
#   certmaker quick --edit
#   certmaker quick HOST DOMAIN ...
#   certmaker paths [HOST]
#   certmaker view CERTFILE
#
# Run
#
#   certmaker help
#
# for a quick-start tutorial.
#
#
# 
# ### Listing profiles
#
# List host profiles
#
#   certmaker paths
#
# List key and certificate for a host profile
#
#   certmaker paths HOST
#
#
# ### Creating and signing profiles (central management)
#
# Create a new host profile, edit it:
#
#     certmaker new host HOST
#     certmaker edit HOST
#
# Regenerate host profile assets
#
#   certmaker renew key { HOST | CONFIG [KEYFILE] }
#   certmaker renew csr { HOST | KEYFILE CONFIG [CSRFILE] }
#
# Sign a host profile or CSR file:
#
#     certmaker sign { HOST | CSRFILE [CERTFILE] }
#
#
# ### Generate new CA or CSRs
#
# Create a new CA:
#
#     certmaker new ca
#
# Create a new CSR:
#
#     certmaker csr CSRNAME [FQDN ...]
#
# ### Certificate viewing and fetching
#
# Fetch a site's certificate, and view a certificate file
#
#   certmaker fetch { DOMAIN | URL }
#
#   certmake view CERTFILE
#
#
###/doc
