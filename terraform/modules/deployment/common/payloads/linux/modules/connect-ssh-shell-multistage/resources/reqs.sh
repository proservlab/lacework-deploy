#!/bin/bash

docker run -it --rm -v "$PWD:/app" --entrypoint=/bin/sh -w /app python:3.10-slim -c "python3 -m pip install pyflakes && python3 -m pip install pipreqs && pipreqs --force . && python3 -m pip install -r requirements.txt; python3 -m compileall -q . && pyflakes *.py"
