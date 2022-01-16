#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd)
mfa_conf=${SCRIPT_DIR}/aws-mfa.conf

# verify exec conditions
if [ ! -e ${mfa_conf} ]; then
  echo "Please set aws-mfa.conf in ${SCRIPT_DIR}."
  exit 1
fi

if [ -z "$1" ]; then
  echo '[Usage] ./set-aws-token.sh {displayed MFA token code}'
  exit 1
fi

# set conf
source ${mfa_conf}
varacckey=aws_access_key_id     # accesskey variable name
varseckey=aws_secret_access_key # secretkey variable name
vartoken=aws_session_token      # token variable name
code=$1                         # MFA code from the parameter

sts=$(aws sts get-session-token --serial-number ${AWS_SERIAL_NUMBER} --duration-seconds ${DURATION} --token-code ${code})

acckey=$(echo ${sts} | jq -r '.Credentials | .AccessKeyId' )
seckey=$(echo ${sts} | jq -r '.Credentials | .SecretAccessKey' )
token=$(echo ${sts} | jq -r '.Credentials | .SessionToken' )
expiration=$(echo ${sts} | jq -r '.Credentials | .Expiration' )

if [ -z ${token} ]; then
  echo ${sts}
  exit 1
fi

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
${varacckey} = ${acckey}
${varseckey} = ${seckey}
${vartoken} = ${token}
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

echo "Expiration: ${expiration}"

exit 0
