#!/bin/bash

# set arguments
acckey=$1
seckey=$2
token=$3
conf_dir=$4

# add the credential to aws credentials
cat <<EOL > ${conf_dir}/.mfa-token
export AWS_ACCESS_KEY_ID=${acckey}
export AWS_SECRET_ACCESS_KEY=${seckey}
export AWS_SESSION_TOKEN=${token}
EOL

