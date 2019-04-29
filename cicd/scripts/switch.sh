#!/bin/bash

###
# shell script to switch Test Listener to Live Listener by calling Stacker module
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


#Set variables for updating Parameter Store
PARAM_LIVE_COLOR="/region/${REGION}/${ENVIRONMENT}/${STACKER_APP}/LiveColor"
LiveColor=$(aws ssm get-parameter --with-decryption --region ${REGION} --name "/region/${REGION}/${ENVIRONMENT}/${STACKER_APP}/LiveColor" | grep -i Value | awk -F '"' '{print $4}')
DockerImageTagBlue=$(aws ssm get-parameter --with-decryption --region ${REGION} --name "/region/${REGION}/${ENVIRONMENT}/${STACKER_APP}/DockerImageTagBlue" | grep -i Value | awk -F '"' '{print $4}')
DockerImageTagGreen=$(aws ssm get-parameter --with-decryption --region ${REGION} --name "/region/${REGION}/${ENVIRONMENT}/${STACKER_APP}/DockerImageTagGreen" | grep -i Value | awk -F '"' '{print $4}')

echo "--------------------------------------------------------------------"
echo "INFO: Validate Parameters"
echo "--------------------------------------------------------------------"
  
  
# Validate Run Time Input
if [ -z ${LiveColor} ]; then
  echo "--------------------------------------------------------------------"
  echo "ERROR: Unable to determine LiveColor:${LiveColor}"
  echo "ERROR: check variables and options for JOB: $JOB_ID"
  echo "--------------------------------------------------------------------"
  exit 1
fi

echo "--------------------------------------------------------------------"
echo "INFO: Current LiveColor: ${LiveColor}"
echo "--------------------------------------------------------------------"

if [ "${LiveColor}" == "blue" ]; then
  echo "--------------------------------------------------------------------"
  echo "INFO: update ${PARAM_LIVE_COLOR} to green"
  echo "--------------------------------------------------------------------"
  new_LiveColor="green"
  LiveColorCommitId=${DockerImageTagGreen}
  aws ssm put-parameter --name ${PARAM_LIVE_COLOR} --type "SecureString" --value ${new_LiveColor} --overwrite --region $REGION
  REVISION=${DockerImageTagGreen}
  old_REVISION=${DockerImageTagBlue}

elif [ "${LiveColor}" == "green" ]; then
  echo "--------------------------------------------------------------------"
  echo "INFO: update ${PARAM_LIVE_COLOR} to blue"
  echo "--------------------------------------------------------------------"
  new_LiveColor="blue"
  LiveColorCommitId=${DockerImageTagBlue}
  aws ssm put-parameter --name ${PARAM_LIVE_COLOR} --type "SecureString" --value ${new_LiveColor} --overwrite --region $REGION    
  REVISION=${DockerImageTagBlue}
  old_REVISION=${DockerImageTagGreen}
else
  echo "--------------------------------------------------------------------"
  echo "ERROR: LiveColor error. Value: ${LiveColor}"
  echo "--------------------------------------------------------------------"
fi

echo "------------------------------------------------------------------------------------------------------------------"
echo "INFO: run stacker to update ALB Live Listener to use the ${new_LiveColor} TargetGroup with ${LiveColorCommitId} Commit Id"
echo "------------------------------------------------------------------------------------------------------------------"

## Create files with vars for use with Groovy
echo ${LiveColorCommitId} > releaseLiveColorCommitId.txt
echo ${LiveColor} > releaseLiveColor.txt
echo ${testColor} > releasetestColor.txt

cd ${WORKSPACE}/Stacker
rstat=$(stacker build --region $REGION conf/environments/${ENVIRONMENT}/${REGION}.yml conf/${STACKER_MODULE})
sstat=$?
echo "INFO: stacker output rstat: ${rstat}"
echo "INFO: status of stacker job sstat: ${sstat}"

## return to WORKSPACE dir
cd ${WORKSPACE}

exit 0
