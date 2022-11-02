#!/bin/bash -x
cd /tmp
WALLETADDRESS="${ wallet }"
REGION="${ region }"
ETCMINTERTARGZ="etcminer-0.20.0-cuda-11-opencl-linux-x86_64.tar.gz"
ETCMINERARGS="-U"
AZID=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone-id | cut -d- -f1)
INSTTYPE=$(curl -s http://169.254.169.254/latest/meta-data/instance-type)
wget -O etcminer.tar.gz https://etcminer-release.s3.amazonaws.com/0.20.0/$${ETCMINTERTARGZ}
tar xvfz etcminer.tar.gz
cd etcminer
case $${AZID:0:1} in
    u) PREFERRED_SERVER="us1-etc";;
    e) PREFERRED_SERVER="eu1-etc";;
    a) PREFERRED_SERVER="asia1-etc";;
    *) PREFERRED_SERVER="us1-etc";;
esac
cat > runner.sh << __EOF__
#!/bin/bash -x
while (true); do
    ./etcminer $${ETCMINERARGS} --exit \
    -P stratums://$${WALLETADDRESS}.$${REGION}@$${PREFERRED_SERVER}.ethermine.org:5555 \
    -P stratums://$${WALLETADDRESS}.$${REGION}@us1-etc.ethermine.org:5555 \
    -P stratums://$${WALLETADDRESS}.$${REGION}@eu1-etc.ethermine.org:5555 \
    -P stratums://$${WALLETADDRESS}.$${REGION}@asia1-etc.ethermine.org:5555 \
    >> /tmp/etcminer.log 2>&1
    sleep 1
done
__EOF__
chmod +x runner.sh
nohup ./runner.sh &