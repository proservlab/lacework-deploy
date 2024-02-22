#!/usr/bin/env bash

# TEMPLATE INPUTS
# enable_secondary_volume: boolean value indicating whether to mount a secondary volume
# enable_swap: boolean value indicating whether to create a swap file (used on low memory instances)
# additional_tasks: shell commands to execute after initial setup
# secondary_disk: the name of the secondary disk volume (e.g. ubuntu is /dev/xvdb)

LOGFILE=/tmp/user-data.log
function log {
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
}
MAXLOG=2
for i in `seq $((MAXLOG-1)) -1 1`; do mv "$LOGFILE."{$i,$((i+1))} 2>/dev/null || true; done
mv $LOGFILE "$LOGFILE.1" 2>/dev/null || true

# Determine Package Manager
if command -v apt-get &>/dev/null; then
    PACKAGE_MANAGER="apt-get"
elif command -v yum &>/dev/null; then
    PACKAGE_MANAGER="yum"
else
    log "Neither apt-get nor yum found. Exiting..."
    exit 1
fi

# Wait for Package Manager
check_package_manager() {
    if [ "$PACKAGE_MANAGER" == "apt-get" ]; then
        pgrep -f "apt" || pgrep -f "dpkg"
    else
        pgrep -f "yum" || pgrep -f "rpm"
    fi
}
while check_package_manager; do
    log "Waiting for $PACKAGE_MANAGER to be available..."
    sleep 10
done

log "Starting..."
%{ if enable_secondary_volume == true }
if [ "$PACKAGE_MANAGER" == "apt-get" ]; then
    sudo $PACKAGE_MANAGER update -y >> $LOGFILE 2>&1
    sudo $PACKAGE_MANAGER install xfsprogs gzip -y >> $LOGFILE 2>&1
else
    sudo $PACKAGE_MANAGER install -y xfsprogs gzip >> $LOGFILE 2>&1
fi

SECONDARY_DISK="${secondary_disk}"
log "secondary volume name: $SECONDARY_DISK"

sudo mkfs -t xfs $SECONDARY_DISK >> $LOGFILE 2>&1
sudo mkdir /data >> $LOGFILE 2>&1
sudo mount $SECONDARY_DISK /data >> $LOGFILE 2>&1
BLK_ID=$(sudo blkid $SECONDARY_DISK | cut -f2 -d" ")
log "BLK_ID: $BLK_ID"
if [[ -z $BLK_ID ]]; then
    log "Hmm ... no block ID found ... "
    exit 1
fi
echo "$BLK_ID     /data   xfs    defaults   0   2" | sudo tee --append /etc/fstab
sudo mount -a >> $LOGFILE 2>&1
log "Creating docker directory on data drive..."
mkdir -p /data/var/lib/docker
ln -sf /data/var/lib/docker /var/lib/docker >> $LOGFILE 2>&1
%{ endif }
%{ if enable_swap == true }
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
%{ endif }

log "running additional tasks..."
${additional_tasks}

log "bootstrapping complete"