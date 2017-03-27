#!/bin/bash

CURRENT_PATH=$(pwd)
AWS_PROFILE="concierge-demo"
BUCKET_NAME="concierge.demo.mangata.io"

function upload_website_to_s3()
{
  printf "~ uploading app to S3 ..."

  myCmd="aws s3 cp code/ \
  s3://$BUCKET_NAME \
  --profile $AWS_PROFILE --recursive"

  message=$(${myCmd[@]} 2>&1 | grep -i 'error')

  if [[ $message ]]; then
    printf "\t[FAIL]\n"
    echo $message
    exit -1
  fi

  printf "\t[OK]\n"
}

# upload all the files to the S3 bucket
upload_website_to_s3
