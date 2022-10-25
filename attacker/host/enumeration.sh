#!/bin/bash

#nmap -sS -A -sC -p 443,22 portquiz.net
curl -L -o /tmp/nmap https://github.com/andrew-d/static-binaries/blob/master/binaries/linux/x86_64/nmap?raw=true
nmap -sS -p 443,22 portquiz.net