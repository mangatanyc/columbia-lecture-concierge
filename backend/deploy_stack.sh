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
DELETE_FLAG_ON=0
SKIP_CODE_UPLOAD_FLAG_ON=0

usage() {
    echo "usage: $0"
    printf "\t -e {dev qa, prod}"
    printf "\n\t -r {AWS_REGION}"
    printf "\n\t -p {AWS_PROFILE}"
    printf "\n\t[-d]\n" 1>&2; exit 1; }

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
        echo "uploading $path"

        # change directory
        pushd "$path"

        # zip files
        zip -qdgds 10M -r $funcName.zip *

        aws s3 cp $funcName.zip s3://$S3_BUCKET_NAME/repos/$ENV/ --profile $AWS_PROFILE

        update_lambda $funcName

        # remove zip
        rm $funcName.zip

        popd
    done < .concierge.config
}

function upload_cf_template_to_s3()
{
    printf "~ uploading CF template to S3 ..."

    # upload to s3
    myCmd="aws s3 cp config/$AWS_CF_TEMPLATE \
    s3://$S3_BUCKET_NAME/configuration/$AWS_CF_TEMPLATE \
    --profile $AWS_PROFILE"

    message=$(${myCmd[@]} 2>&1 | grep -i 'error')

    if [[ $message ]]; then
        printf "\t[FAIL]\n"
        echo $message
        exit -1
    fi

    printf "\t[OK]\n"
}

function upload_swagger_json_to_s3()
{
    printf "~ uploading Swagger template to S3 ..."

    # upload to s3
    myCmd="aws s3 cp config/$SWAGGER_FILE \
    s3://$S3_BUCKET_NAME/configuration/$SWAGGER_FILE \
    --profile $AWS_PROFILE"

    message=$(${myCmd[@]} 2>&1 | grep -i 'error')

    if [[ $message ]]; then
        printf "\t[FAIL]\n"
        echo $message
        exit -1
    fi

    printf "\t[OK]\n"
}

function validate_cf_template()
{
    printf "~ validating CF template ..."

    # validate cf template
    myCmd="aws cloudformation validate-template \
    --template-body file://config/$AWS_CF_TEMPLATE \
    --profile $AWS_PROFILE"

    message=$(${myCmd[@]} 2>&1 | grep -i 'error')

    if [[ $message ]]; then
        printf "\t\t[FAIL]\n"
        echo $message
        exit -1
    fi

    printf "\t\t[OK]\n"
}

function deploy_cf_template()
{
    printf "~ deploying CF template ..."

    # validate cf template
    myCmd="aws cloudformation create-stack \
    --stack-name $STACK_NAME-$ENV \
    --capabilities CAPABILITY_NAMED_IAM \
    --template-body file://config/$AWS_CF_TEMPLATE \
    --parameters  ParameterKey=ApiStageParam,ParameterValue=$ENV \
                  ParameterKey=RegionParam,ParameterValue=$REGION \
                  ParameterKey=StackNameParam,ParameterValue=$STACK_NAME \
                  ParameterKey=ConfigurationS3BucketName,ParameterValue=$S3_BUCKET_NAME \
    --region $REGION
    --profile $AWS_PROFILE"

    message=$(${myCmd[@]} 2>&1)
    error=$(echo $message | grep -i 'error')

    if [[ $error ]]; then
        printf "\t\t[FAIL]\n"
        echo $error
        exit -1
    fi

    printf "\t\t[OK]\n"
    echo $message
    echo "Completed '$STACK_NAME-$ENV' stack deployment."
}

function delete-stack()
{
    printf "~ deleting stack ..."

    aws cloudformation delete-stack \
    --stack-name $STACK_NAME-$ENV \
    --profile $AWS_PROFILE

    printf "\t\t\t[OK]\n"
}

# get flags
while getopts "d?q?p:?e:r:" o; do
    case "${o}" in
        d)
            DELETE_FLAG_ON=1
            ;;
        e)
            ENV=${OPTARG}
            ;;
        p)
            AWS_PROFILE=${OPTARG}
            ;;
        q)
            SKIP_CODE_UPLOAD_FLAG_ON=1
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

# check if delete flag is set
# if so prompt to delete the stack
if [ $DELETE_FLAG_ON = 1 ]; then
    echo "Warning: You are about to delete the '$STACK_NAME-$ENV' stack. This action is irreversible."
    printf "Are you sure? (y, n): "

    while read line
    do
        if [ $line != "y" ] && [ $line != "n" ]; then
            printf "Are you sure? (y, n): "
        else
            if [ $line = "n" ]; then
                exit 0
            else
                break
            fi
        fi
    done

    echo "Deleting stack '$STACK_NAME-$ENV':"

    delete-stack
    exit 0
fi

echo "Starting '$STACK_NAME-$ENV' stack deployment:" ;

if [ $SKIP_CODE_UPLOAD_FLAG_ON = 0 ]; then
    # upload code repos
    upload_lambda_functions
else
    printf "~ skipping code upload ...\t\t[OK]\n"
fi

# validate the integrity of the deployment template
validate_cf_template

# upload the cf template to s3 for reference
upload_cf_template_to_s3

# upload the swagger template to s3 for reference
upload_swagger_json_to_s3

# start deployment
deploy_cf_template
