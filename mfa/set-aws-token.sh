#!/bin/bash

cred=~/.aws/credentials    # credentials filepath
vartoken=aws_session_token # token variable name
duration=$((60*60*24))     # 1 day
code=$1                    # MFA code

if [ -z "${AWS_SERIAL_NUMBER}" ]; then
  echo "Please set your MFA device ARN to environment variable AWS_SERIAL_NUMBER."
  exit 1
fi

if [ -z "${code}" ]; then
  echo '[Usage] ./set-aws-token.sh {displayed MFA token code}'
  exit 1
fi

# clear token from aws credentials
sed -i "/${vartoken}/d" ${cred}

sts=$(aws sts get-session-token --serial-number ${AWS_SERIAL_NUMBER} --duration-seconds ${duration} --token-code ${code})

token=$(echo ${sts} | jq -r '.Credentials | .SessionToken' )

if [ -z ${token} ]; then
  echo ${sts}
  exit 1
fi

# add token to aws credentials
echo "${vartoken} = ${token}" >> ${cred}

echo "success"

exit 0
