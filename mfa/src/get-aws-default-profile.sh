#!/bin/bash

mfa_conf=$1
source ${mfa_conf}

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

# find target profile line
profile_lines=$(sed -n "/^\[${LOGIN_PROFILE}\]$/,/^\[/p" ${CRED})
AWS_ACCESS_KEY_ID=$(echo "$profile_lines" | grep "aws_access_key_id" | awk '{print $3}')
AWS_SECRET_ACCESS_KEY=$(echo "$profile_lines" | grep "aws_secret_access_key" | awk '{print $3}')

