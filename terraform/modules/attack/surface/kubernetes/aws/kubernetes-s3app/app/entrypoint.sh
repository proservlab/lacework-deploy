#!/bin/sh
mkdir p /s3-mountpoint
mount-s3 $BUCKET_NAME /s3-mountpoint
export FLASK_APP=./app.py
export FLASK_DEBUG=0
flask run -h 0.0.0.0 -p 80