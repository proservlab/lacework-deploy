import logging
import pymysql
from pymysql.err import DatabaseError
import boto3
import botocore.session
import os
from botocore.utils import InstanceMetadataFetcher
from botocore.credentials import InstanceMetadataProvider

list_of_names = ""

# use ec2 instance role
provider = InstanceMetadataProvider(iam_role_fetcher=InstanceMetadataFetcher(timeout=1000, num_attempts=2))
creds = provider.load()

session = boto3.Session(
    aws_access_key_id=creds.access_key,
    aws_secret_access_key=creds.secret_key,
    aws_session_token=creds.token,
    region_name='us-east-1'
)

ssm = session.client('ssm')

parameter = ssm.get_parameter(Name='db_host', WithDecryption=True)
DB_APP_URL=parameter['Parameter']['Value'].split(":")[0]
DB_PORT=int(parameter['Parameter']['Value'].split(":")[1])

parameter = ssm.get_parameter(Name='db_name', WithDecryption=True)
DB_NAME=parameter['Parameter']['Value']

parameter = ssm.get_parameter(Name='db_username', WithDecryption=True)
DB_USER_NAME=parameter['Parameter']['Value']

parameter = ssm.get_parameter(Name='db_password', WithDecryption=True)
DB_PASSWORD=parameter['Parameter']['Value']


parameter = ssm.get_parameter(Name='db_region', WithDecryption=True)
DB_REGION=parameter['Parameter']['Value'] 

os.environ['LIBMYSQL_ENABLE_CLEARTEXT_PLUGIN'] = '1'

SSL_CA='rds-combined-ca-bundle.pem'

client = session.client('rds')
ssl = {'ca': 'rds-combined-ca-bundle.pem'}
token = client.generate_db_auth_token(DBHostname=DB_APP_URL, Port=DB_PORT, DBUsername=DB_USER_NAME, Region=DB_REGION)
print(token)
connection = pymysql.connect(
                            host=DB_APP_URL,
                            user=DB_USER_NAME,
                            password=token,
                            port=DB_PORT,
                            db=DB_NAME,
                            ssl=ssl,
                            charset='utf8mb4',
                            cursorclass=pymysql.cursors.DictCursor
)

cursor = connection.cursor()
cursor.execute("SELECT `firstName`, `lastName`, `characterName` FROM `cast`")

cast_list = []
for row in cursor.fetchall():
    cast_list.append({'firstName': row["firstName"], 'lastName': row["lastName"], 'characterName': row["characterName"]})

print(cast_list)

cursor.close()
connection.close() 

