#!/bin/bash

sudo apt-get update && \
	sudo apt-get install -y git cmake build-essential libboost-all-dev && \
	git clone -b Linux https://github.com/nicehash/nheqminer.git && \
	cd nheqminer/cpu_xenoncat/Linux/asm/ && \
	./fasm -m 640000 equihash_avx1.asm && \
    ./fasm -m 640000 equihash_avx2.asm && \
	cd ../../../Linux_cmake/nheqminer_cpu && \
	cmake . && \
	make -j $(nproc)

# run miner
./nheqminer_cpu -l equihash.usa.nicehash.com:3357 -u 3HotyetPPdD6pyGWtZvmMHLcXxmNuWR53C.worker1 &