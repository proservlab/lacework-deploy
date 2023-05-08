# coding:utf8
# much fun: https://github.com/u17zl/SSTI-flask-session-forge

import uuid
from flask import Flask, request, make_response, session,render_template, url_for, redirect, render_template_string
from flask_api import status
import os
import pymysql
from pymysql.err import DatabaseError
import json
import sys
import boto3
from botocore.utils import InstanceMetadataFetcher
from botocore.credentials import InstanceMetadataProvider

app = Flask(__name__)
app.config['SECRET_KEY']='Hello World!'

# use ec2 instance role
provider = InstanceMetadataProvider(iam_role_fetcher=InstanceMetadataFetcher(timeout=1000, num_attempts=2))
creds = provider.load()

session = boto3.Session(
    aws_access_key_id=creds.access_key,
    aws_secret_access_key=creds.secret_key,
    aws_session_token=creds.token,
    region_name='${region}'
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

app.logger.info(SSL_CA)

# use provided cluster pod iam role to get db token
client = session.client('rds')

# Connect to the database
def create_connection():
    # Construct SSL
    ssl = {'ca': 'rds-combined-ca-bundle.pem'}
    token = client.generate_db_auth_token(DBHostname=DB_APP_URL, Port=DB_PORT, DBUsername=DB_USER_NAME, Region=DB_REGION)
    return pymysql.connect(host=DB_APP_URL,
                             user=DB_USER_NAME,
                             password=token,
                             port=DB_PORT,
                             db=DB_NAME,
                             ssl=ssl,
                             charset='utf8mb4',
                             cursorclass=pymysql.cursors.DictCursor
    )


@app.route('/')
def index():
    
    app.logger.info(request.cookies)
    try:
        username=session['username']
        return render_template("index.html",username=username)
    except Exception:
    
        return """<form action="%s" method='post'>
            <input type="text" name="username" required>
            <input type="password" name="password" required>
            <input type="submit" value="submit">
            </form>""" %url_for("login")

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
        if username=="admin" and password!=str(uuid.uuid4()):
            return "login failed"
        app.logger.info(url_for('index'))
        resp = make_response(redirect(url_for("index")))
        session['username']=username
        return resp
    else:
        return "login failed"

@app.route('/catalog')
def catalog():
    app.logger.info('Inside Get request')
    try:
        connection = create_connection()
        cursor = connection.cursor()
        cursor.execute("SELECT `prodId`, `prodName` FROM `product`")

        payload = []
        content = {}
        list_of_names = {}
        for row in cursor.fetchall():
            prodId = str(row["prodId"])
            prodName = str(row["prodName"])
            list_of_names[prodId] = prodName
            content = {row['prodId']:row['prodName']}
            payload.append(content)
        app.logger.info(list_of_names)
        cursor.close()
        connection.close()  
        return {
            "products": list_of_names
        }
    except DatabaseError as e:
        err_code = e.args[0]
        if err_code == 2003:
            app.logger.error('bad connection string')
        return 'Error: Bad connection string', status.HTTP_500_INTERNAL_SERVER_ERROR
    except KeyError as e:
        app.logger.error('Error 500 Could not retrieve information ' + e.__doc__ )
        return 'Error: Could not retrieve information', status.HTTP_500_INTERNAL_SERVER_ERROR
    except Exception as e:
        app.logger.error('Error 400 Could not retrieve information ' + e.__doc__ )
        return 'Error: Could not retrieve information', status.HTTP_400_BAD_REQUEST

@app.errorhandler(404)
def page_not_found(e):
    template='''
        {%% block body %%}
        <div class="center-content error">
        <h1>Oops! That page doesn't exist.</h1>
        <h3>%s</h3>
        </div>
        {%% endblock %%}
    '''%(request.url)
    return render_template_string(template),status.HTTP_400_BAD_REQUEST

@app.route("/logout")
def logout():
    resp = make_response(redirect(url_for("index")))
    session.pop('username')
    return resp

if __name__ == "__main__":  
    app.run(port=80, debug=True)