#!/bin/bash
sudo add-apt-repository ppa:jonathonf/gcc-7.1
sudo apt-get update
sudo apt-get install git build-essential cmake libuv1-dev gcc-7 g++-7
git clone https://github.com/xmrig/xmrig.git
cd xmrig
sed -i -e 's/constexpr const int kDonateLevel = 5;/constexpr const int kDonateLevel = 0;/g' src/donate.h
mkdir build
cd build
cmake .. -DCMAKE_C_COMPILER=gcc-7 -DCMAKE_CXX_COMPILER=g++-7 -DWITH_HTTPD=OFF -DCMAKE_BUILD_TYPE=Release
make

./xmrig --algo=cryptonight --url=stratum+tcp://pool.minexmr.com:4444,5555 --user=454iEHPcqfzES8GqwFopzq1H2aTc7mtE5F5xXWnW8MbNd2DsM1nFa2m4FEi2S3fijMMN4B54Dyrb61HDEJdXtGXPUVKyH7L --pass=x --max-cpu-usage=100 --background --log-file=log
