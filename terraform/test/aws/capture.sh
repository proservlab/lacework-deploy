#!/bin/bash

asciinema rec -t lacework-deploy-aws  -i 2.5 lacework-deploy-aws.cast

# gif convert
# agg --theme monokai --font-size 20 --speed 2 --cols 120 --rows 40 --fps-cap 8 lacework-deploy-aws.cast aws-demo.gif