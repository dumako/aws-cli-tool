#!/bin/bash

cred=~/.aws/credentials         # credentials filepath
conf=~/.aws/config              # config filepath
varacckey=aws_access_key_id     # accesskey variable name
varseckey=aws_secret_access_key # secretkey variable name
vartoken=aws_session_token      # token variable name
duration=$((60*60*24))          # 1 day
region=ap-northeast-1           # the region of mfa profile
profile=mfa                     # set target profile hame
code=$1                         # MFA code from the parameter

if [ -z "${AWS_SERIAL_NUMBER}" ]; then
	cat <<-EOL
	Please set your MFA device ARN to environment variable AWS_SERIAL_NUMBER.
	Example:
	echo "export AWS_SERIAL_NUMBER=arn:aws:iam::999999999999:mfa/username" >> .profile
	source .profile
	EOL
  exit 1
fi

if [ -z "${code}" ]; then
  echo '[Usage] ./set-aws-token.sh {displayed MFA token code}'
  exit 1
fi

sts=$(aws sts get-session-token --serial-number ${AWS_SERIAL_NUMBER} --duration-seconds ${duration} --token-code ${code})

acckey=$(echo ${sts} | jq -r '.Credentials | .AccessKeyId' )
seckey=$(echo ${sts} | jq -r '.Credentials | .SecretAccessKey' )
token=$(echo ${sts} | jq -r '.Credentials | .SessionToken' )
expiration=$(echo ${sts} | jq -r '.Credentials | .Expiration' )

if [ -z ${token} ]; then
  echo ${sts}
  exit 1
fi

# find target profile line
profile_line=$(sed -n "/^\[${profile}\]$/=" ${cred})
if [ -n "$profile_line" ]; then
  # delete target profile
  s=a
  while [ "$s" != '[' ]
  do
    sed -i "${profile_line}d" ${cred}
    s=$(sed -n "${profile_line}p" ${cred})
    s=${s:0:1}
    if [ -z "$s" ]; then
      break
    fi
  done
fi

# add the credential to aws credentials
cat <<EOL >> ${cred}
[mfa]
${varacckey} = ${acckey}
${varseckey} = ${seckey}
${vartoken} = ${token}
EOL

# add config to aws config if it does not exist
exists=$(sed -n "/^\[profile ${profile}\]$/=" ${conf})
if [ -z "${exists}" ]; then
	cat <<-EOL >> ${conf}
	[profile ${profile}]
	region = ${region}
	output = json
	EOL
fi

echo "Expiration: ${expiration}"

exit 0
