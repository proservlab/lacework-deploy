#!/bin/bash
LOGFILE=/tmp/user-data.log
function log {
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
}
truncate -s 0 $LOGFILE
check_apt() {
    pgrep -f "apt" || pgrep -f "dpkg"
}
while check_apt; do
    log "Waiting for apt to be available..."
    sleep 10
done
log "Starting..."
sudo apt update
sudo apt -y install google-osconfig-agent
log "enabling swap file..."
sudo dd if=/dev/zero of=/swapfile bs=128M count=32
log "dd swap file created..."
log "setting swap file permissions..."
sudo chmod 600 /swapfile
log "running mkswap..."
sudo mkswap /swapfile
log "running swapon..."
sudo swapon /swapfile
sudo swapon -s
log "appending swap file to fstab"
sudo echo "/swapfile swap swap defaults 0 0" >> /etc/fstab 
log "Bootstrapping Complete!"