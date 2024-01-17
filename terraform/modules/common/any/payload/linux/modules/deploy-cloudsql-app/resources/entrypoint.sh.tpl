#!/bin/bash

export FLASK_APP=${app_path}
export FLASK_DEBUG=1
flask run -h 0.0.0.0 -p ${listen_port}