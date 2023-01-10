#!/bin/bash

sudo docker build . -t 172.20.0.11:32000/vote:0.0.14
sudo docker push 172.20.0.11:32000/vote
