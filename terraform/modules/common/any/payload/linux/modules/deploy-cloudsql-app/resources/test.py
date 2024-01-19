import uuid
import logging
from flask import Flask, request, make_response, session, render_template, url_for, redirect, render_template_string
from flask_api import status
import os
import pymysql
from pymysql.err import DatabaseError
import json
import sys
import ssl
import urllib.request
from google.cloud.sql.connector import Connector, IPTypes
from google.cloud import secretmanager
from google.auth import compute_engine
from google.auth import transport
from google.auth import default
from google.auth.compute_engine import _metadata

credentials, project_id = default()
auth_req = transport.requests.Request()
credentials.refresh(auth_req)

# initialize Connector object
connector = Connector(ip_type=IPTypes.PRIVATE, enable_iam_auth=True,)

app = Flask(__name__)
app.config['SECRET_KEY'] = 'Hello World!'

# Create a Secret Manager client
client = secretmanager.SecretManagerServiceClient(credentials=credentials)
service_account_email = credentials.service_account_email
db_username = service_account_email.split('@')[0]


def access_secret_version(secret_id):
    # Build the resource name of the secret version.
    name = f"projects/{project_id}/secrets/{secret_id}/versions/latest"
    # Access the secret version.
    response = client.access_secret_version(request={"name": name})
    return response.payload.data.decode('UTF-8')


# Retrieve your database connection details from Secret Manager
DB_APP_URL = access_secret_version('db_host')
DB_PORT = int(access_secret_version('db_port'))
DB_NAME = access_secret_version('db_name')
DB_USER_NAME = access_secret_version('db_username')
DB_PASSWORD = access_secret_version('db_password')
DB_PRIVATE_IP = access_secret_version('db_private_ip')
DB_PUBLIC_IP = access_secret_version('db_public_ip')

os.environ['LIBMYSQL_ENABLE_CLEARTEXT_PLUGIN'] = '1'

# function to return the database connection

# # iam access via cloudsql proxy
# def getconn() -> pymysql.connections.Connection:
#     conn: pymysql.connections.Connection = connector.connect(
#         DB_APP_URL,
#         "pymysql",
#         user=db_username,
#         # password=credentials.token,
#         db=DB_NAME,
#         enable_iam_auth=True,
#         ip_type=IPTypes.PRIVATE,
#     )
#     return conn
# connection = getconn()

# # iam access via private
# def create_connection():
#     # Construct SSL
#     ctx = ssl.create_default_context()
#     ctx.check_hostname = False
#     ctx.verify_mode = ssl.VerifyMode.CERT_NONE
#     token = credentials.token
#     return pymysql.connect(host=DB_PRIVATE_IP,
#                            user=db_username,
#                            password=token,
#                            port=DB_PORT,
#                            db=DB_NAME,
#                            ssl=ctx,
#                            charset='utf8mb4',
#                            cursorclass=pymysql.cursors.DictCursor
#                            )
# connection = create_connection()

# sql user access via private


def create_connection():
    # Construct SSL
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.VerifyMode.CERT_NONE
    return pymysql.connect(host=DB_PRIVATE_IP,
                           user=DB_USER_NAME,
                           password=DB_PASSWORD,
                           port=DB_PORT,
                           db=DB_NAME,
                           ssl=ctx,
                           charset='utf8mb4',
                           cursorclass=pymysql.cursors.DictCursor
                           )


connection = create_connection()


cursor = connection.cursor()
cursor.execute("SELECT `firstName`, `lastName`, `characterName` FROM `cast`")

cast_list = []
for row in cursor.fetchall():
    cast_list.append(
        {'firstName': row["firstName"], 'lastName': row["lastName"], 'characterName': row["characterName"]})

print(cast_list)

cursor.close()
connection.close()
