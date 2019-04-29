#!/bin/bash

###
# shell script to deploy docker image to ECS cluster by calling Stacker module
#

# Install Dependencies

echo "--------------------------------------------------------------------"
echo "DEBUG: variables"
echo "--------------------------------------------------------------------"


echo "WORKSPACE: ${WORKSPACE}"
echo "ENVIRONMENT: ${ENVIRONMENT}"
echo "REGION: ${REGION}"
echo "STACKER_APP: ${STACKER_APP}"


echo "--------------------------------------------------------------------"
echo "DEBUG: assume roles"
echo "--------------------------------------------------------------------"

echo "AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID}"
echo
echo

