#!/bin/bash

###
# shell script to deploy docker image to ECS cluster by calling Stacker module
#

#Go to WORKSPACE directory
cd ${WORKSPACE}

# Authenticate to AWS
echo "--------------------------------------------------------------------"
echo "INFO: Assume AWS Role"
echo "--------------------------------------------------------------------"

## Assume role based on environment
if [ "${ENVIRONMENT}" == "dev" ]; then
  role_arn="arn:aws:iam::1234567890:role/dev-cross-account-stacker-role-IamRole-UYNH89H30KL"
elif [ "${ENVIRONMENT}" == "prod" ]; then
  role_arn="arn:aws:iam::0987654321:role/prod-cross-account-stacker-role-IamRole-IK8933JFHNB"
elif [ "${ENVIRONMENT}" == "stage" ]; then
  role_arn="arn:aws:iam::1234567890:role/dev-cross-account-stacker-role-IamRole-UYNH89H30KL"
fi

role_session_name="$ENVIRONMENT"
IFS=" " read AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN <<< $(aws sts assume-role --role-arn="$role_arn" --role-session-name="$role_session_name" --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' --output=text)

export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN

PARAM_LIVE_COLOR="/region/${REGION}/${ENVIRONMENT}/${STACKER_APP}/LiveColor"
LiveColor=$(aws ssm get-parameter --with-decryption --region ${REGION} --name "/region/${REGION}/${ENVIRONMENT}/${STACKER_APP}/LiveColor" | grep -i Value | awk -F '"' '{print $4}')
DockerImageTagBlue=$(aws ssm get-parameter --with-decryption --region ${REGION} --name "/region/${REGION}/${ENVIRONMENT}/${STACKER_APP}/DockerImageTagBlue" | grep -i Value | awk -F '"' '{print $4}')
DockerImageTagGreen=$(aws ssm get-parameter --with-decryption --region ${REGION} --name "/region/${REGION}/${ENVIRONMENT}/${STACKER_APP}/DockerImageTagGreen" | grep -i Value | awk -F '"' '{print $4}')

echo "-----------------------------"
echo "INFO: LiveColor: ${LiveColor}"
echo "-----------------------------"

if [ "${LiveColor}" == "green" ]; then
    echo "----------------------------------------------------------"
    echo "INFO: update Test DockerImageTagBlue to ${COMMIT_ID}"
    echo "----------------------------------------------------------"
    aws ssm put-parameter --name /region/${REGION}/${ENVIRONMENT}/${STACKER_APP}/DockerImageTagBlue --type "SecureString" --value ${COMMIT_ID} --overwrite --region $REGION    
    testColor="blue"
    LiveColorCommitId="${DockerImageTagGreen}"

elif [ "${LiveColor}" == "blue" ]; then
    echo "----------------------------------------------------------"
    echo "INFO: update Test DockerImageTagGreen to ${COMMIT_ID}"
    echo "----------------------------------------------------------"

    aws ssm put-parameter --name /region/${REGION}/${ENVIRONMENT}/${STACKER_APP}/DockerImageTagGreen --type "SecureString" --value ${COMMIT_ID} --overwrite --region $REGION
    testColor="green"
    LiveColorCommitId="${DockerImageTagBlue}"
else
    echo "----------------------------------------------------------"
    echo "ERROR: unable to find LiveColor, value ${LiveColor}"
    echo "----------------------------------------------------------"
    echo
    exit 1
fi

## Create files with vars for use with Groovy
echo ${LiveColorCommitId} > deployLiveColorCommitId.txt
echo ${LiveColor} > deployLiveColor.txt
echo ${testColor} > deploytestColor.txt

echo "---------------------------------------------------------------------------------------------"
echo "INFO: Run Stacker Job Stacker/conf/${STACKER_MODULE} to deploy ${COMMIT_ID} to ${ENVIRONMENT} Test ${STACKER_APP}"
echo "---------------------------------------------------------------------------------------------"

## Run stacker
cd ${WORKSPACE}/Stacker
stacker build --region ${REGION} conf/environments/${ENVIRONMENT}/${REGION}.yml conf/${STACKER_MODULE}

#return to WORKSPACE dir
cd ${WORKSPACE}

exit 0
