#!/bin/bash

sudo docker build . -t 172.20.0.11:32000/result:0.0.1
sudo docker push 172.20.0.11:32000/result
