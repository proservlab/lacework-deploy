#!/bin/bash
docker run --name=ctfd --rm -p 8000:8000 -v $(pwd)/ctfd_data:/opt/CTFd/CTFd/.data --user root -it my-custom-ctfd
