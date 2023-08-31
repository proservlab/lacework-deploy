#!/bin/bash

python3 -m pip install setuptools==57.0.0 --force-reinstall
python3 -m pip install wheel==0.36.2 --force-reinstall
python3 -m pip uninstall comtypes
python3 -m pip install --no-cache-dir comtypes
