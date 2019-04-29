#!/bin/bash

usage() {
  echo
  echo "Verify an application health check has a COMMIT_ID"
  echo "USAGE: $0 -u <url> -c <commit id>"
  echo
  echo "options:"
  echo "-u (required) application health check url"
  echo "-c (required) git commit id"
  echo "-h help"
  echo
}

while getopts :u:c:h flag; do
  case $flag in
    u ) url=$OPTARG ;;
    c ) commit_id=$OPTARG ;;
    h ) usage; exit 1 ;;
    H ) usage; exit 1 ;;
    \? ) echo -e \\n"Unknown option $OPTARG "\\n; usage; exit 2 ;;
    : ) echo "option -$OPTARG requires an argument. "; usage; exit 2 ;;
    * ) echo "Unimplemented option: -$OPTARG"; usage; exit 2 ;;
  esac
done

if [ -z $url ] || [ -z $commit_id ];then
 usage
 exit 2
fi

## get healthcheck metrics
response=$(curl --write-out %{http_code} --silent --output /dev/null $url)

echo

#if ((response >=205)); then
# Check if the http response_code is between 200-204
if ((response >= 200 && response <=204)); then

    ## parse out health check info
    stat=$(curl -s $url)

    ## convert metrics for influxdb line output
    commit=$(echo $stat | jq .commit | tr -d '"')
    if [[ $commit_id == $commit ]];then
	echo "-----------------------------------------------------------------------------------------"
	echo "INFO: COMMIT_ID: $commit_id is installed and available on $url"
	echo "-----------------------------------------------------------------------------------------"
	exit 0
    else
	echo "-----------------------------------------------------------------------------------------"
	echo "ERROR: COMMIT_ID: $commit_id not installed, current installed COMMIT_ID: $commit"
	echo "-----------------------------------------------------------------------------------------"
	exit 1
    fi
else
    # response not valid
	  echo "-----------------------------------------------------------------------------------------"
    echo "ERROR: response code $response"
    echo "ERROR: url $url"
	  echo "-----------------------------------------------------------------------------------------"
    exit 1
fi
