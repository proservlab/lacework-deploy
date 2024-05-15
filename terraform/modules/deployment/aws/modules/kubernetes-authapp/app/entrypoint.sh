#!/bin/sh
export FLASK_APP=./app.py
export FLASK_DEBUG=0
flask run -h 0.0.0.0 -p 80