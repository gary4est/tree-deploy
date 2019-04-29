#!/usr/bin/env python

## Verify an application health check endpoint has a commit_id 
## installed and the health check is healthy

import sys
import json
import requests
from argparse import ArgumentParser

# Arguments 
parser = ArgumentParser(prog='verify_commit_id.py', usage='%(prog)s [options]')
parser.add_argument("-u", "--url", required=True,
                    help="Application health check URL")
parser.add_argument("-c", "--commit", required=True,
                    help="Commit Id to verify against health check")
args = parser.parse_args()

app_url = args.__dict__["url"]
commit_id = args.__dict__["commit"]

# Request app_url and get response
try:
    r = requests.get(app_url,timeout=10)
    r.raise_for_status()
except requests.exceptions.HTTPError as errh:
    print ("ERROR: Http Error:",errh)
    sys.exit(1)
except requests.exceptions.ConnectionError as errc:
    print ("ERROR: Connection error:",errc)
    sys.exit(1)
except requests.exceptions.Timeout as errt:
    print ("ERROR: Timeout error:",errt)
    sys.exit(1)
except requests.exceptions.RequestException as err:
    print ("ERROR: failure with {app_url}",err)
    sys.exit(1)
else:
    print('')

response_dict = r.json()
commit = response_dict['commit']
healthy = response_dict['healthy']
connection_status = response_dict['connection_status']

#verify commit_id is install and healthy
if healthy and connection_status and commit == commit_id:
    print('--------------------------------------------------------------------------------------------------')
    print(f'INFO: COMMIT_ID: {commit_id} is installed and available on {app_url}')
    print('--------------------------------------------------------------------------------------------------')
    print('')
else:
    print('--------------------------------------------------------------------------------------------------')
    print(f'ERROR: COMMIT_ID: {commit_id} is not installed, current installed COMMIT_ID: {commit}') 
    print('--------------------------------------------------------------------------------------------------')
    print('')
    sys.exit(1)

