#!/bin/bash

docker run -it -e "USERPWD=user" -e "ADMINPWD=admin" --rm -p 8000:8000 -v "$PWD:/app" --entrypoint=/bin/sh -w /app python:3.10-slim -c "python3 -m pip install -r requirements.txt && python3 -m pip install pipreqs && pipreqs --force ."
