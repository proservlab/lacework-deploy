#!/usr/bin/env python3
# vim: set fileencoding=utf8 :
import boto3
import time
import json
import os
import sys
import argparse

script_directory = os.path.dirname(os.path.abspath(sys.argv[0]))

def execute_athena_query(query_string, athena_results_bucket_name, athena_database_name):
    # Execute the query
    query_execution = client.start_query_execution(
        QueryString=query_string,
        QueryExecutionContext={
            'Database': athena_database_name
        },
        ResultConfiguration={
            'OutputLocation': f's3://{athena_results_bucket_name}/'
        }
    )

    query_execution_id = query_execution['QueryExecutionId']

    # Wait for query to complete
    while True:
        status = client.get_query_execution(QueryExecutionId=query_execution_id)
        query_state = status['QueryExecution']['Status']['State']
        if query_state in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
            break
        time.sleep(1)

    # Fetch and return results
    if query_state == 'SUCCEEDED':
        final_results = []
        next_token = None

        while True:
            if next_token:
                results = client.get_query_results(
                    QueryExecutionId=query_execution_id,
                    NextToken=next_token
                )
            else:
                results = client.get_query_results(
                    QueryExecutionId=query_execution_id
                )

            final_results.extend(results['ResultSet']['Rows'])
            next_token = results.get('NextToken', None)

            if not next_token:
                break

        return final_results
    else:
        return f"Query failed with status: {query_state}"

def generate_iam_policy(events):
    with open(f'{script_directory}/mappings.json', 'r') as f:
        mappings = json.load(f)
    
    unique_actions = set()    
    for event in events:
        eventsource = event['Data'][0]['VarCharValue'].split('.')[0]
        eventname = event['Data'][1]['VarCharValue']
        
        if eventsource != "eventsource" or eventname != "eventname":
            action = f"{eventsource}:{eventname}"
            action_lower = f"{eventsource.lower()}.{eventname.lower()}"
            found_mapping = False
            # search for API to IAM policy mapping (this is probably better done in pandas)
            for key, value in mappings['sdk_method_iam_mappings'].items():
                if key.lower() == action_lower:
                    found_mapping = True
                    print(f"Found mapping: {action} => {value[0]['action']}")
                    action = value[0]['action']
                    break
            
            # iam:TagRole not captured in cloudtrail (append it)
            if action == "iam:CreateRole":
                unique_actions.add("iam:TagRole")

            if action == "s3:CreateBucket":
                unique_actions.add("s3:ListBucket")

            if action == "ec2:CreateVpc":
                unique_actions.add("ec2:CreateTags")

            if action == "ecs:RegisterTaskDefinition":
                unique_actions.add("iam:PassRole")

            # to troubleshoot errors
            unique_actions.add("sts:DecodeAuthorizationMessage")

            # add unique actions only
            unique_actions.add(action)

    policy = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": list(sorted(unique_actions)),
                "Resource": "*"
            }
        ]
    }

    return policy

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Execute Athena query and generate IAM policy.')
    parser.add_argument('--profile', required=True, help='AWS profile to use.')
    parser.add_argument('--output', required=True, help='Path to output IAM policy.')
    parser.add_argument('--test-name', required=True, help='The AWS_EXECUTION_ENV value to search user-agent for.')
    args = parser.parse_args()

    # intiate the session with the profile name
    session = boto3.Session(profile_name=args.profile)
    client = session.client('athena')

    with open(f'{script_directory}/athena-settings.json', 'r') as f:
        settings = json.load(f)

    athena_database_name = settings['athena_database_name']['value']
    athena_results_bucket_name = settings['athena_results_bucket_name']['value']
    athena_workgroup_name = settings['athena_workgroup_name']['value']
    
    query_string=f'SELECT DISTINCT eventsource, eventname FROM cloudtrail_logs WHERE userAgent LIKE \'% exec-env/{args.test_name}%\' ORDER BY eventsource, eventname;'
    events = execute_athena_query(
        query_string=query_string, 
        athena_database_name=athena_database_name,
        athena_results_bucket_name=athena_results_bucket_name
    )
    policy = generate_iam_policy(events=events)

    with open(args.output, 'w') as f:
        json.dump(policy, f, indent=4)

    print(f"Policy has been written to {args.output}")