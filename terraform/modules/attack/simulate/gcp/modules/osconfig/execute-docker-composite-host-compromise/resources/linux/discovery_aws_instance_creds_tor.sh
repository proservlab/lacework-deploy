#!/bin/bash

SCRIPTNAME=$(basename $0)
LOGFILE=/tmp/$SCRIPTNAME.log
function log {
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
}
MAXLOG=2
for i in `seq $((MAXLOG-1)) -1 1`; do mv "$LOGFILE."{$i,$((i+1))} 2>/dev/null || true; done
mv $LOGFILE "$LOGFILE.1" 2>/dev/null || true
check_apt() {
  pgrep -f "apt" || pgrep -f "dpkg"
}
while check_apt; do
  log "Waiting for apt to be available..."
  sleep 10
done

# check for required aws cli
if ! command -v aws > /dev/null; then
    log "aws cli not found - installing..."
    sudo apt-get update && sudo apt-get install -y awscli
    log "done"
fi;

# build aws credentials file locally with ec2 crentials
log "Pulling ec2 instance credentials..."
INSTANCE_PROFILE=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials)
AWS_ACCESS_KEY_ID=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$INSTANCE_PROFILE | grep "AccessKeyId" | awk -F ' : ' '{ print $2 }' | tr -d ',' | xargs)
AWS_SECRET_ACCESS_KEY=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$INSTANCE_PROFILE | grep "SecretAccessKey" | awk -F ' : ' '{ print $2 }' | tr -d ',' | xargs)
AWS_SESSION_TOKEN=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$INSTANCE_PROFILE | grep "Token" | awk -F ' : ' '{ print $2 }' | tr -d ',' | xargs)

# create an env file for scoutsuite
log "Building env file for scoutsuite..."
cat > .aws-ec2-instance <<-EOF
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN}
AWS_DEFAULT_REGION=us-east-1
AWS_DEFAULT_OUTPUT=json
EOF

# update local aws config
log "Update local aws configuration adding ec2 instance as profile: attacker"
PROFILE="attacker"
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID --profile=$PROFILE
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY --profile=$PROFILE
aws configure set aws_session_token $AWS_SESSION_TOKEN --profile=$PROFILE

# reset docker containers
log "Stopping and removing any existing tor containers..."
docker stop torproxy > /dev/null 2>&1
docker rm torproxy > /dev/null 2>&1
docker stop scoutsuite-tor > /dev/null 2>&1
docker rm scoutsuite-tor > /dev/null 2>&1

# start tor proxy
log "Starting tor proxy..."
docker run -d --rm --name torproxy -p 9050:9050 dperson/torproxy

# build scoutsuite proxychains
log "Building proxychains config..."
TORPROXY_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' torproxy)
cat > proxychains.conf <<- EOF
dynamic_chain
proxy_dns
tcp_read_time_out 15000
tcp_connect_time_out 8000
[ProxyList]
socks5  ${TORPROXY_IP}  9050
EOF
log "Building scoutesuite-tor entrypoint.sh..."
cat > entrypoint.sh <<- EOF
#!/bin/sh
set -e
# Check if the TOR connection is up
while ! proxychains curl -s --connect-timeout 5 http://icanhazip.com 2> /dev/null; do
    echo "Waiting for TOR connection..."
    sleep 5
done
# Run scoutsuite with TOR proxy
proxychains scout "\${@}"
EOF
chmod +x entrypoint.sh
log "Building scoutesuite-tor Dockerfile..."
cat > Dockerfile <<- EOF
FROM rossja/ncc-scoutsuite:aws-latest
RUN apt-get update && apt-get install -y netcat-openbsd proxychains4 curl
COPY proxychains.conf /etc/proxychains4.conf
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
EOF
docker build -t scoutsuite-tor .
log "Running scoutesuite-tor with aws discovery..."
docker run --rm --link torproxy:torproxy --env-file=.aws-ec2-instance scoutsuite-tor aws