#!/usr/bin/env python
# vim: set fileencoding=utf8 :
import boto3
import time
import json

# Initialize Athena client
session = boto3.Session(profile_name='lwst5')
client = session.client('athena')

athena_database = "cloudtrail_db"
athena_results_bucket = "athena-results-zizr"

# Get the saved named query
named_query_id = 'ccb7e6c3-796c-4e16-baed-bcb07294853b' # create_table_cloudtrail
# named_queries = client.list_named_queries()
# print(named_queries)
response = client.get_named_query(NamedQueryId=named_query_id)
create_table_query_string = response['NamedQuery']['QueryString']

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

    query_string='SELECT DISTINCT eventsource, eventname FROM cloudtrail_logs WHERE userAgent LIKE \'%terra-exec%\' ORDER BY eventsource, eventname;'
    results = execute_athena_query(
        query_string=query_string, 
        athena_database=athena_database,
        athena_results_bucket=athena_results_bucket)
    
    for result in results:
        eventsource = result['Data'][0]['VarCharValue']
        eventname = result['Data'][1]['VarCharValue']
        print({
            "eventsource" : eventsource,
            "eventname" : eventname
        })
