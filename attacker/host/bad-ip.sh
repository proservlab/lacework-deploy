#!/bin/bash

curl -s https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level2.netset | grep -v "#" | awk -v num_line=$((1 + $RANDOM % 1000)) 'NR == num_line' | tr -d "\n" | xargs -I {} nc -w 1 -vv {} 80
curl -s https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level2.netset | grep -v "#" | awk -v num_line=$((1 + $RANDOM % 1000)) 'NR == num_line' | tr -d "\n" | xargs -I {} nc -w 1 -vv {} 443

