#!/bin/bash

CURRENT_PATH=$(pwd)

AWS_PROFILE=""
BUCKET_NAME="<YOUR-CONFIG-S3-BUCKET-NAME>"

usage() {
    echo "usage: $0"
    printf "\t -p {AWS_PROFILE}\n" 1>&2; exit 1; }

function check_profile()
{
    if [ -z $AWS_PROFILE ]; then
        echo "error: missing aws profile"
        usage
        exit -1
    fi
}

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

# get flags
while getopts "p:" o; do
    case "${o}" in
        p)
            AWS_PROFILE=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

# check if the AWS_PROFILE variable is set
check_profile

# upload all the files to the S3 bucket
upload_website_to_s3
