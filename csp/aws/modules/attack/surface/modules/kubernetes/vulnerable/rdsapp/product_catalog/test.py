import logging
import pymysql
from pymysql.err import DatabaseError
import boto3
import os

DB_APP_URL = "database"
DB_USER_NAME = "workshop_user"
DB_NAME = "dev"
DB_PORT = 3306
DB_REGION = "us-east-1"

list_of_names = ""


os.environ['LIBMYSQL_ENABLE_CLEARTEXT_PLUGIN'] = '1'

SSL_CA='rds-combined-ca-bundle.pem'

client = boto3.client('rds')
ssl = {'ca': 'rds-combined-ca-bundle.pem'}
token = client.generate_db_auth_token(DBHostname=DB_APP_URL, Port=3306, DBUsername=DB_USER_NAME, Region=DB_REGION)
print(token)
connection = pymysql.connect(host=DB_APP_URL,
                            user=DB_USER_NAME,
                            password=token,
                            port=3306,
                            db=DB_NAME,
                            ssl=ssl,
                            charset='utf8mb4',
                            cursorclass=pymysql.cursors.DictCursor
)


cursor = connection.cursor()
cursor.execute("SELECT `prodId`, `prodName` FROM `product`")

payload = []
content = {}
#mydict = create_dict()
list_of_names = {}
for row in cursor.fetchall():
    prodId = str(row["prodId"])
    prodName = str(row["prodName"])
    list_of_names[prodId] = prodName
print(list_of_names)
connection.close()