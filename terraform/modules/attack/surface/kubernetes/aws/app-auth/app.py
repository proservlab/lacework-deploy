#!/usr/bin/env python3

# flask-unsign --wordlist /usr/share/wordlists/rockyou.txt --unsign --cookie '<cookie>' --no-literal-eval
# flask-unsign --sign --cookie "{'logged_in': True}" --secret 'CHANGEME'

from dataclasses import dataclass, asdict
from flask import Flask, jsonify, request, Response, abort, redirect, url_for, render_template, flash, render_template_string
from flask_login import LoginManager, login_user, logout_user, login_required, current_user, UserMixin
import os
import json
import sys
import boto3
from botocore.exceptions import NoCredentialsError
from werkzeug.utils import secure_filename
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy_mixins import AllFeaturesMixin
import sqlalchemy as sa
import datetime

from collections import defaultdict

app = Flask(__name__)
login_manager = LoginManager()
login_manager.init_app(app)
app.config['SECRET_KEY'] = 'Hello World!'

app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
db = SQLAlchemy(app)

app.app_context().push()

######### Models #########


class BaseModel(db.Model, AllFeaturesMixin):
    __abstract__ = True
    pass


@dataclass
class User(UserMixin, BaseModel):
    id: int
    username: str
    email: str
    password: str
    created_at: datetime.datetime
    role: str

    id = sa.Column(sa.Integer, primary_key=True, autoincrement=True)
    username = sa.Column(sa.Text, unique=True, nullable=False)
    email = sa.Column(sa.Text, unique=True, nullable=False)
    password = sa.Column(sa.Text, unique=True, nullable=False)
    created_at = sa.Column(sa.DateTime, default=datetime.datetime.utcnow)
    role = sa.Column(sa.Text, nullable=False)


######## Initialize ########
BaseModel.set_session(db.session)

######## Create test entity ########
db.create_all()
user = User.create(
    username='user', email="user@interlacelabs.com", password=os.environ["USERPWD"], role="user")
password = User.create(
    username='admin', email="admin@interlacelabs.com", password=os.environ["ADMINPWD"], role="admin")


@login_manager.user_loader
def load_user(id):
    return User.query.get(int(id))


@login_manager.unauthorized_handler
def unauthorized_callback():
    redirect_next = ""
    if not str(request.path).startswith("/logout"):
        redirect_next = f"?next={request.path}"
    return redirect('/login' + redirect_next)


@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form.get('username', None)
        password = request.form.get('password', None)
        user = User.query.filter_by(
            username=request.form['username']).first()
        if user != None and request.form['password'] == user.password:
            login_user(user)
            dest = request.args.get('next')
            if dest is not None:
                return redirect(dest)
            else:
                return redirect("/")
        else:
            return abort(401)
    else:
        return render_template('login.html')


@app.route('/logout')
@login_required
def logout():
    logout_user()
    return Response('logout sucess.<br/><a href="/login">login</a>')


@app.route("/users")
@login_required
def table_list():
    columns = []
    mapper = sa.inspect(User)
    for column in mapper.attrs:
        columns.append({
            "field": column.key,  # which is the field's name of data key
            "title": column.key,  # display as the table header's name
            "sortable": True,
        })
    users = User.query.order_by(User.username).all()
    print(json.dumps(users, default=lambda d: {
        k["field"]: str(getattr(d, k["field"])) for k in columns}))
    print(users)
    return render_template("table.html", data=users, columns=columns)


@app.route("/content", methods=['GET'])
def content():
    content = request.args.get("content")
    return render_template_string(content)


@app.route('/')
@login_required
def home():
    return Response(f"{current_user.username}: <a href='/logout'>Logout</a>")


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8088, debug=True)
