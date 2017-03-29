#!/bin/bash

CURRENT_PATH=$(pwd)

REGION=""
AWS_PROFILE=""
SWAGGER_FILE="swagger.json"
# specify the name of your locally set up AWS profile
STACK_NAME="concierge-stack"
AWS_CF_TEMPLATE="cloudformation.template"
# specify the name of a S3 bucket that you set up to
# host various configuration files and repositories related to this deployment
S3_BUCKET_NAME="<YOUR-CONFIG-S3-BUCKET-NAME>"

ENV=""
FUNC="all"
CODE_ONLY=0

usage() {
    echo "usage: $0"
    printf "\t -e {dev qa, prod}"
    printf "\n\t -r {AWS_REGION}"
    printf "\n\t -p {AWS_PROFILE}"
    printf "\n\t[-c ./code/{PATH_TO_FUNCTION}]\n" 1>&2; exit 1; }

function check_environment()
{
    if [ -z $ENV ]; then
        echo "error: missing environment"
        usage
        exit -1
    fi

    if [ $ENV != "dev" ] && [ $ENV != "qa" ] && [ $ENV != "prod" ]; then
        echo "error: missing environment"
        usage
        exit -1
    fi
}

function check_region()
{
    if [ -z $REGION ]; then
        echo "error: missing region"
        usage
        exit -1
    fi
}

function check_profile()
{
    if [ -z $AWS_PROFILE ]; then
        echo "error: missing aws profile"
        usage
        exit -1
    fi
}

function update_lambda()
{
    aws lambda update-function-code \
    --region $REGION \
    --function-name $STACK_NAME-$ENV-$1 \
    --zip-file fileb://$1.zip \
    --profile $AWS_PROFILE
}

function upload_lambda_functions()
{
    while IFS=, read path funcName
    do
        if [ "$FUNC" != "all" ]; then
            if [ "$FUNC" != $path ]; then
                echo "skipping $path"
                continue
            else
                echo "uploading $path"
            fi
        fi

        # change directory
        pushd "$path"

        # zip files
        zip -qdgds 10M -r $funcName.zip *

        aws s3 cp $funcName.zip s3://$S3_BUCKET_NAME/repos/$ENV/ --profile $AWS_PROFILE

        if [ $CODE_ONLY -eq 1 ]; then
            update_lambda $funcName
        fi

        # remove zip
        rm $funcName.zip

        popd
    done < .concierge.config
}

# get flags
while getopts "c:?d?q?p:?e:r:" o; do
    case "${o}" in
        c)
            FUNC=${OPTARG}
            CODE_ONLY=1
            ;;
        e)
            ENV=${OPTARG}
            ;;
        p)
            AWS_PROFILE=${OPTARG}
            ;;
        r)
            REGION=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

# check if the ENV variable is set
check_environment

# check if the REGION variable is set
check_region

# check if the AWS_PROFILE variable is set
check_profile

echo "Starting '$STACK_NAME-$ENV' stack deployment:" ;

# upload code repos
upload_lambda_functions
