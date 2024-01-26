# coding:utf8
# much fun: https://github.com/u17zl/SSTI-flask-session-forge

import uuid
from flask import Flask, request, make_response, session, render_template, url_for, redirect, render_template_string
from flask_api import status
import os
import json
import sys
import boto3
from werkzeug.utils import secure_filename
from botocore.exceptions import NoCredentialsError

app = Flask(__name__)
app.config['SECRET_KEY'] = 'Hello World!'

# Initialize the Boto3 S3 client
s3_client = boto3.client('s3')

BUCKET_NAME = os.environ.get("BUCKET_NAME")


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


@app.route("/login/", methods=['POST'])
def login():
    username = request.form.get("username")
    password = request.form.get("password")
    app.logger.info(username)
    if username.strip():
        if username != "admin" and password != str(uuid.uuid4()):
            return "login failed"

        app.logger.info(url_for('index'))
        resp = make_response(redirect(url_for("index")))
        session['username'] = username
        return resp
    else:
        return "login failed"


@app.route("/content", methods=['GET'])
def content():
    content = request.args.get("content")
    return render_template_string(content)


@app.route('/upload', methods=['GET', 'POST'])
def upload():
    app.logger.info(request.cookies)
    try:
        username = session['username']
        if request.method == 'POST':
            # Handle file upload
            if 'file' in request.files:
                file = request.files['file']
                if file.filename == '':
                    return 'No selected file', 400
                if file:
                    filename = secure_filename(file.filename)
                    try:
                        s3_client.upload_fileobj(file, BUCKET_NAME, filename)
                        return 'File uploaded successfully', 200
                    except NoCredentialsError:
                        return 'Credentials not available', 403
        else:
            # Display page with forms
            upload_form = """
            <h2>Upload a file</h2>
            <form action="{upload_url}" method="post" enctype="multipart/form-data">
                <input type="file" name="file">
                <input type="submit" value="Upload">
            </form>
            """.format(upload_url=url_for('index'))

            return render_template("upload.html", username=username, upload_form=upload_form)
    except Exception:
        # Fallback login form
        return """<form action="%s" method='post'>
            <input type="text" name="username" required>
            <input type="password" name="password" required>
            <input type="submit" value="submit">
            </form>""" % url_for("login")


@app.route('/download/<filename>', methods=['GET'])
def download_file(filename):
    try:
        response = s3_client.get_object(Bucket=BUCKET_NAME, Key=filename)
        return response['Body'].read(), 200
    except NoCredentialsError:
        return 'Credentials not available', 403
    except s3_client.exceptions.NoSuchKey:
        return 'File not found', 404


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
