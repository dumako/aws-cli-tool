#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd)
mfa_conf=${SCRIPT_DIR}/aws-mfa.conf
code=$1 # MFA code from the parameter

# verify exec conditions
if [ ! -e ${mfa_conf} ]; then
  echo "Please set aws-mfa.conf in ${SCRIPT_DIR}."
  exit 1
fi

if [ -z "${code}" ]; then
  echo '[Usage] ./set-aws-token.sh {displayed MFA token code}'
  exit 1
fi

# set conf
source ${mfa_conf}
source ${SCRIPT_DIR}/src/get-aws-default-profile.sh ${mfa_conf}

sts=$(aws sts get-session-token --serial-number ${AWS_SERIAL_NUMBER} --duration-seconds ${DURATION} --token-code ${code})

acckey=$(echo ${sts} | jq -r '.Credentials | .AccessKeyId' )
seckey=$(echo ${sts} | jq -r '.Credentials | .SecretAccessKey' )
token=$(echo ${sts} | jq -r '.Credentials | .SessionToken' )
expiration=$(echo ${sts} | jq -r '.Credentials | .Expiration' )

if [ -z ${token} ]; then
  echo ${sts}
  exit 1
fi

. ${SCRIPT_DIR}/src/set-aws-config.sh ${acckey} ${seckey} ${token} ${mfa_conf}

echo "Expiration: ${expiration}"

exit 0
