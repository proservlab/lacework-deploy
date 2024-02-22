# coding:utf8
# much fun: https://github.com/u17zl/SSTI-flask-session-forge

# some fun: /content?content={{%20config%20}}


import uuid
# import logging
from flask import Flask, request, make_response, session, render_template, url_for, redirect, render_template_string
from flask_api import status
import os
import pymysql
# from pymysql.err import DatabaseError
# import json
# import sys
# import ssl
import secrets
from google.cloud.sql.connector import Connector, IPTypes
from google.cloud import secretmanager
# from google.auth import compute_engine
from google.auth import transport
from google.auth import default
# from google.auth.compute_engine import _metadata

# Use the IAM service account for authentication
credentials, project_id = default()
auth_req = transport.requests.Request()
credentials.refresh(auth_req)

# initialize Connector object
connector = Connector(ip_type=IPTypes.PRIVATE, enable_iam_auth=True,)

app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', secrets.token_hex(32))

# app.config['SECRET_KEY'] = os.environ.get(
#     'SECRET_KEY', 'change_this_super_secret_random_string')

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
DB_CERT = access_secret_version('db_cert')

os.environ['LIBMYSQL_ENABLE_CLEARTEXT_PLUGIN'] = '1'

SSL_CA = os.path.abspath('cloudsql-combined-ca-bundle.pem')
with open(SSL_CA, 'w') as f:
    f.write(DB_CERT)

app.logger.info(SSL_CA)


def create_connection():
    # Construct SSL
    ssl_config = {
        'ca': SSL_CA,
        'check_hostname': False,
    }
    token = credentials.token
    return pymysql.connect(host=DB_PRIVATE_IP,
                           user=db_username,
                           password=token,
                           port=DB_PORT,
                           db=DB_NAME,
                           ssl=ssl_config,
                           charset='utf8mb4',
                           cursorclass=pymysql.cursors.DictCursor
                           )


@app.route('/')
def index():

    app.logger.info(request.cookies)
    try:
        username = session['username']
        return render_template("index.html", username=username)
    except Exception:

        return """<form action="%s" method='post'>
            <input type="text" name="username" required>
            <input type="password" name="password" required>
            <input type="submit" value="submit">
            </form>""" % url_for("login")


@app.route("/content", methods=['GET'])
def content():
    content = request.args.get("content")
    return render_template_string(content)


@app.route("/login/", methods=['POST'])
def login():
    username = request.form.get("username")
    password = request.form.get("password")
    app.logger.info(username)
    if username.strip():
        if username == "admin" and password != str(uuid.uuid4()):
            return "login failed"
        app.logger.info(url_for('index'))
        resp = make_response(redirect(url_for("index")))
        session['username'] = username
        return resp
    else:
        return "login failed"


@app.route('/cast')
def cast():
    app.logger.info('Inside Get request')
    try:
        connection = create_connection()
        cursor = connection.cursor()
        cursor.execute(
            "SELECT `firstName`, `lastName`, `characterName` FROM `cast`")

        cast_list = []
        for row in cursor.fetchall():
            cast_list.append(
                {'firstName': row["firstName"], 'lastName': row["lastName"], 'characterName': row["characterName"]})

        cursor.close()
        connection.close()

        return render_template('cast.html', cast=cast_list)
    except Exception as e:
        app.logger.error(f"Exception occurred: {e}")


@app.errorhandler(404)
def page_not_found(e):
    template = '''
        {%% block body %%}
        <div class="center-content error">
        <h1>Oops! That page doesn't exist.</h1>
        <h3>%s</h3>
        </div>
        {%% endblock %%}
    ''' % (request.url)
    return render_template_string(template), status.HTTP_400_BAD_REQUEST


@app.route("/logout")
def logout():
    resp = make_response(redirect(url_for("index")))
    session.pop('username')
    return resp


if __name__ == "__main__":
    app.run(port=80, debug=True)
