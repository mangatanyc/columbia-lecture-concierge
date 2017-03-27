#!/bin/bash

CURRENT_PATH=$(pwd)

REGION="us-east-1"
AWS_PROFILE="concierge-demo"
STACK_NAME="columbia-concierge"

FUNC="all"

usage() { echo "Usage: $0 [-c {PATH_TO_FUNCTION_CODE}]" 1>&2; exit 1; }

function update_lambda()
{
    aws lambda update-function-code \
    --region $REGION \
    --function-name $1 \
    --zip-file fileb://$1.zip \
    --profile $AWS_PROFILE
}

function update_lambda_functions()
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

        update_lambda $funcName

        # remove zip
        rm $funcName.zip

        popd
    done < .concierge.config
}

# get flags
while getopts "c:?" o; do
    case "${o}" in
        c)
            FUNC=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

echo "Starting '$STACK_NAME' stack deployment:" ;

# archive & upload code
update_lambda_functions
