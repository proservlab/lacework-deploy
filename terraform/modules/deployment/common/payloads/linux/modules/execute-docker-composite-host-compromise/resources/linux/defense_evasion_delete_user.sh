#!/bin/bash

useradd -m -s /bin/bash attacker
usermod -aG sudo attacker
sudo -u attacker -i /bin/bash -c "whoami"
userdel attacker