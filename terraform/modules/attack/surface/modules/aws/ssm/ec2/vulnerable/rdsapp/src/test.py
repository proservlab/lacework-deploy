import boto3

session = boto3.session.Session(region_name='us-east-1')
region = session.region_name


# use current region
ssm = boto3.client('ssm',region_name=region)

parameter = ssm.get_parameter(Name='db_host', WithDecryption=True)
DB_HOST=parameter['Parameter']['Value']

parameter = ssm.get_parameter(Name='db_name', WithDecryption=True)
DB_NAME=parameter['Parameter']['Value']

parameter = ssm.get_parameter(Name='db_username', WithDecryption=True)
DB_USERNAME=parameter['Parameter']['Value']

parameter = ssm.get_parameter(Name='db_password', WithDecryption=True)
DB_PASSWORD=parameter['Parameter']['Value']
