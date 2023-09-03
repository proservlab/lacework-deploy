#!/usr/bin/env python
# vim: set fileencoding=utf8 :
import boto3
import time
import json
import os
import sys

script_directory = os.path.dirname(os.path.abspath(sys.argv[0]))

# Initialize Athena client
session = boto3.Session(profile_name='lwst5')
client = session.client('athena')

athena_database = "cloudtrail_db_zizr"
athena_results_bucket = "athena-results-zizr"
athena_workgroup = "athena-workgroup-zizr"
test_id='perms-test-lacework-agentless'

# Get the saved named query
named_queries = client.list_named_queries(WorkGroup=athena_workgroup)
response = client.get_named_query(NamedQueryId=named_queries['NamedQueryIds'][0])


def execute_athena_query(query_string, athena_results_bucket, athena_database):
    # Execute the query
    query_execution = client.start_query_execution(
        QueryString=query_string,
        QueryExecutionContext={
            'Database': athena_database
        },
        ResultConfiguration={
            'OutputLocation': f's3://{athena_results_bucket}/'
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

# Example usage
if __name__ == '__main__':
    # result = execute_athena_query(
    #     query_string='SHOW DATABASES', 
    #     athena_database=athena_database,
    #     athena_results_bucket=athena_results_bucket)

    # print(result)

    # result = execute_athena_query(
    #     query_string=f'SHOW TABLES in {database}', 
    #     athena_database=athena_database,
    #     athena_results_bucket=athena_results_bucket)

    # print(result)


    # create the database table
    # result = execute_athena_query(
    #     query_string=create_table_query_string, 
    #     athena_database=athena_database,
    #     athena_results_bucket=athena_results_bucket)

    # print(result)

    # query_string='SELECT * FROM cloudtrail_logs WHERE userAgent LIKE \'%terra-exec%\' LIMIT 10;'
    # result = execute_athena_query(
    #     query_string=query_string, 
    #     athena_database=athena_database,
    #     athena_results_bucket=athena_results_bucket)
    # print(result)

    if response['NamedQuery']['Name'] != "create_table_cloudtrail":
        print(f"Unexpected query in named queries result. Received '{response['NamedQuery']['Name']}' but expected 'create_table_cloudtrail'")
        exit(1)
    else:
        print("Successfull retrieved create table query.")

    create_table_query_string = response['NamedQuery']['QueryString']
    events = execute_athena_query(
        query_string=create_table_query_string, 
        athena_database=athena_database,
        athena_results_bucket=athena_results_bucket
    )

    query_string=f'SELECT DISTINCT eventsource, eventname FROM cloudtrail_logs WHERE userAgent LIKE \'% exec-env/{test_id}%\' ORDER BY eventsource, eventname;'
    events = execute_athena_query(
        query_string=query_string, 
        athena_database=athena_database,
        athena_results_bucket=athena_results_bucket
    )
    policy = generate_iam_policy(events=events)

    print(json.dumps(policy, indent=4))


# errorcode = 'AccessDenied'