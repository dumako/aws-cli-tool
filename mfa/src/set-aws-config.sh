#!/bin/bash

# set arguments
acckey=$1
seckey=$2
token=$3
mfa_conf=$4

# set conf
source ${mfa_conf}

# find target profile line
profile_line=$(sed -n "/^\[${MFA_PROFILE}\]$/=" ${CRED})
if [ -n "$profile_line" ]; then
  # delete target profile
  s=a
  while [ "$s" != '[' ]
  do
    sed -i "${profile_line}d" ${CRED}
    s=$(sed -n "${profile_line}p" ${CRED})
    s=${s:0:1}
    if [ -z "$s" ]; then
      break
    fi
  done
fi

# add the credential to aws credentials
cat <<EOL >> ${CRED}
[${MFA_PROFILE}]
aws_access_key_id = ${acckey}
aws_secret_access_key = ${seckey}
aws_session_token = ${token}
EOL

# add config to aws config if it does not exist
exists=$(sed -n "/^\[profile ${MFA_PROFILE}\]$/=" ${CONF})
if [ -z "${exists}" ]; then
	cat <<-EOL >> ${CONF}
	[profile ${MFA_PROFILE}]
	region = ${REGION}
	output = ${OUTPUT}
	EOL
fi
