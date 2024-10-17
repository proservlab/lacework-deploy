#!/bin/bash -x

NICE_HASH_USER="xxxx"
MINERGATE_USER="xxxx"

# docker                  
sudo docker run -d --network=host --name xmrig_miner xmrig/xmrig -o us-east.ethash-hub.miningpoolhub.com:20535 -u ${ minergate_user } -p x
sudo docker run -d --network=host --name nicehash_miner a2ncer/nheqminer_cpu:latest -l :3357 -u ${ nicehash_user }

# local
NICE_HASH_USER="xxxx"
MINERGATE_USER="xxxx"

VERSION=6.5.3

rm -rf xmrig*
curl -L https://github.com/xmrig/xmrig/releases/download/v${VERSION}/xmrig-${VERSION}-linux-x64.tar.gz -o xmrig.tar.gz --silent
tar xvfz xmrig.tar.gz
cd xmrig-${VERSION}
cat<<EOF > config.json
{
"algo": "cryptonight",
"pools": [
    {
        "url": "us-east.ethash-hub.miningpoolhub.com:20535",
        "user": "${MINERGATE_USER}",
        "pass": "x",
        "enabled": true,
    }
],
"retries": 10,
"retry-pause": 3,
"watch": true
}
EOF
./xmrig -c config.json