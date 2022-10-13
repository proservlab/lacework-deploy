#!/bin/bash

curl -s https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/iblocklist_ciarmy_malicious.netset | grep -v "#" | awk -v num_line=$((1 + $RANDOM % 1000)) 'NR == num_line' | tr -d "\n" | xargs -I {} nc -w 1 -vv {} 32454

