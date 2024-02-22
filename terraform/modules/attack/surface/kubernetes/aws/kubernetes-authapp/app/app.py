#!/usr/bin/env python3

# flask-unsign --wordlist /usr/share/wordlists/rockyou.txt --unsign --cookie '<cookie>' --no-literal-eval
# flask-unsign --sign --cookie "{'logged_in': True}" --secret 'CHANGEME'
# example: flask-unsign --wordlist /tmp/wordlist.txt --unsign --cookie '.eJwlzjEOwyAMQNG7eO6AMcZ2LhOBMWpX0kxV795U2b70l_eBfa44nrC91xkP2F8DNoiwzmaVhV0JfRRxV09Jc1ERbPM_mVt14tLTIOY0S7AiofkknBThESFoI0jRe7OC0Qc3Ly1rZqwq5lRlzFwFr26sWZS7Jbgg5xHr1mT4_gCH3C6B.ZbafkA.ypRR8lv-t9NxnlTk-lDz0IHoK6M' --no-literal-eval
# [*] Session decodes to: {'_fresh': True, '_id': 'ee9b5996575c831cd47cc8c008248771af996555a6c354b0d3550f4e581319cf31f3eeceee719de381cba941ebd5ac4a282516879c367df267179ca582785b90', '_user_id': '2'}
# [*] Starting brute-forcer with 8 threads..
# [+] Found secret key after 1 attempts
# b'Hello World!'
# example: flask-unsign --sign --cookie "{'_fresh': True, '_id': 'ee9b5996575c831cd47cc8c008248771af996555a6c354b0d3550f4e581319cf31f3eeceee719de381cba941ebd5ac4a282516879c367df267179ca582785b90', '_user_id': '1'}" --secret 'Hello World!'
# .eJwlzjEOwyAMQNG7eO6AMcZ2LhOBMWpX0kxV795U2b70l_eBfa44nrC91xkP2F8DNoiwzmaVhV0JfRRxV09Jc1ERbPM_mVt14tLTIOY0S7AiofkknBThESFoI0jRe7OC0Qc3Ly1rZqwq5lRlzFwFr26sWZS7Jbgg5xHr1iB8f4fZLoA.ZbajkQ.v_65FKzXlncYwwZlFddBKB-n0ak


from dataclasses import dataclass, asdict
from flask import Flask, jsonify, request, Response, abort, redirect, url_for, render_template, session, flash, render_template_string
from flask_login import LoginManager, login_user, logout_user, login_required, current_user, UserMixin, AnonymousUserMixin
from functools import wraps
import os
import json
import sys
from werkzeug.utils import secure_filename
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy_mixins import AllFeaturesMixin
import sqlalchemy as sa
import datetime
import secrets

from collections import defaultdict

app = Flask(__name__)

# app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', secrets.token_hex(32))
app.config['SECRET_KEY'] = os.environ.get(
    'SECRET_KEY', 'change_this_super_secret_random_string')

app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get(
    'SQLALCHEMY_DATABASE_URI', 'sqlite:///:memory:')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = bool(os.environ.get(
    'SQLALCHEMY_TRACK_MODIFICATIONS', False))
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
    role = sa.Column(sa.Text, default="user", nullable=False)


@dataclass
class Anonymous(AnonymousUserMixin):
    def __init__(self):
        self.username = 'Guest'
        self.role = None
        self.is_authenticated = False

    def is_authenticated(self, value):
        self.is_authenticated = value


@dataclass
class Product(db.Model):
    id: int
    name: str
    description: str
    price: float

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.String(100))
    price = db.Column(db.Float, nullable=False)


# Define Role model
class Role(db.Model):
    id = db.Column(db.Integer(), primary_key=True)
    name = db.Column(db.String(50), unique=True)

# Define UserRoles model


class UserRoles(db.Model):
    id = db.Column(db.Integer(), primary_key=True)
    user_id = db.Column(db.Integer(), db.ForeignKey(
        'user.id', ondelete='CASCADE'))
    role_id = db.Column(db.Integer(), db.ForeignKey(
        'role.id', ondelete='CASCADE'))

######## Initialize ########


login_manager = LoginManager()
login_manager.anonymous_user = Anonymous
login_manager.init_app(app)

BaseModel.set_session(db.session)


def initialize_database():
    db.create_all()
    products = [
        Product(name='Laptop',
                description='A high-performance laptop.', price=999.99),
        Product(name='Smartphone',
                description='A new generation smartphone.', price=499.99),
    ]

    # create users
    users = [
        User.create(
            username='user', email="user@interlacelabs.com", password=os.environ.get("USERPWD", secrets.token_hex(32)), role="user"),
        User.create(
            username='admin', email="admin@interlacelabs.com", password=os.environ.get("ADMINPWD", secrets.token_hex(32)), role="admin")
    ]

    db.session.bulk_save_objects(products)
    db.session.bulk_save_objects(users)
    db.session.commit()


def requires_roles(roles):
    """ Flask decorator that allow to allow role authorization with flask_login. """
    def fwrap(f):
        @wraps(f)
        def wrapped_f(*args, **kwargs):
            if not current_user.role in roles:
                return abort(401)
            return f(*args, **kwargs)
        return wrapped_f
    return fwrap


initialize_database()


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
    return render_template('logout.html')


@app.route('/products')
@login_required
@requires_roles(["user", "admin"])
def products():
    columns = []
    mapper = sa.inspect(Product)
    for column in mapper.attrs:
        columns.append({
            "field": column.key,  # which is the field's name of data key
            "title": column.key,  # display as the table header's name
            "sortable": True,
        })
    print(columns)
    products = Product.query.order_by(Product.name).all()
    data = json.loads(json.dumps(products, default=lambda d: {
        k["field"]: str(getattr(d, k["field"])) for k in columns}))
    print(data)
    return render_template("table.html", data=data, columns=columns, request=request)


@app.route("/users")
@requires_roles(["admin"])
@login_required
def users():
    columns = []
    mapper = sa.inspect(User)
    for column in mapper.attrs:
        if column.key in ["id", "username", "email", "role"]:
            columns.append({
                "field": column.key,  # which is the field's name of data key
                "title": column.key,  # display as the table header's name
                "sortable": True,
            })
    users = User.query.with_entities(
        User.id, User.username, User.email, User.role).order_by(User.id).all()
    print(users)
    data = json.loads(json.dumps(users, default=lambda d: {
        k["field"]: str(getattr(d, k["field"])) for k in columns}))
    return render_template("table.html", data=data, columns=columns, request=request)


@app.route('/add-to-cart/<int:product_id>')
def add_to_cart(product_id):

    if 'cart' not in session:
        session['cart'] = []

    session['cart'].append(product_id)
    return jsonify({"cart": session['cart']})

# expose feature flag


@app.route('/debug/feature-status')
@requires_roles("admin")
@login_required
def feature_status():
    # Get feature name from cookie
    feature_name = session.get('FEATURE_FLAG')
    # Insecure retrieval of environment variable based on cookie value
    # WARNING: This introduces a security vulnerability
    if feature_name:
        feature_status = os.environ.get(feature_name, 'Not Found')
    else:
        feature_name = 'Not found'
        feature_status = 'Not found'
    return jsonify({
        "Session": {"FEATURE_FLAG": feature_name},
        "Environment": {
            "Variable": {"FEATURE_FLAG": feature_status}
        }
    })

# SSTI - allow config render
# @app.route("/content", methods=['GET'])
# def content():
#     content = request.args.get("content")
#     return render_template_string(content)


@app.route('/')
def home():
    if 'cart' not in session:
        session['cart'] = []

    return render_template("home.html", current_user=current_user, request=request)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80, debug=True)
