#!/usr/bin/env python3
from flask import Flask
app = Flask(__name__)

@app.route("/")
def home():
    return "Flask 1.0.2 Home page"

if __name__ == '__main__':
    app.run(threaded=True,host='0.0.0.0',port=5000)