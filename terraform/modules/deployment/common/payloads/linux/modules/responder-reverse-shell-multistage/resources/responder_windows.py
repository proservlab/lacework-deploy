#!/usr/bin/env python3
from email.policy import default
import os
from pwncat.modules import BaseModule, Argument
from pwncat.manager import Session
from pwncat.platform.windows import Windows, PowershellError
from pathlib import Path
import time
import subprocess
import shutil
import tarfile
import base64
from datetime import datetime


class Module(BaseModule):
    PLATFORM = [Windows]
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

        session_lock = Path("/tmp/pwncat_windows_session.lock")
        task_name = "default"

        try:
            session.log(f"creating session lock: {session_lock}")
            session_lock.touch()

            def run_remote(session, payload, cwd='C:\Windows\Temp', timeout=7200, retries=3, retry_delay=5):
                attempt = 0
                while attempt < retries:
                    try:
                        session.log(
                            f"Running payload: {payload}, attempt {attempt + 1}")
                        result = session.platform.powershell(
                            payload, cwd=cwd, timeout=timeout)
                        if result.returncode == 0:
                            session.log("Payload executed successfully.")
                            return result
                        else:
                            session.log(
                                f"Payload execution failed with return code: {result.returncode}")
                            session.log(f"Error output: {result.stderr}")
                    except subprocess.TimeoutExpired:
                        session.log(
                            f"Timeout expired after {timeout} seconds for payload: {payload}")
                    except subprocess.CalledProcessError as e:
                        session.log(f"Subprocess error: {e}")
                    except Exception as e:
                        session.log(f"An unexpected error occurred: {e}")
                    attempt += 1
                    if attempt < retries:
                        session.log(f"Retrying in {retry_delay} seconds...")
                        time.sleep(retry_delay)

                session.log(
                    "All retries exhausted. Payload execution failed.")
                return None

            # get hostname for disk loggings
            hostname = session.platform.getenv('HOSTNAME')

            script_dir = os.path.dirname(os.path.realpath(__file__))
            session.log(f"script dir: {script_dir}")
            # task_name = session.platform.getenv("TASK")
            # if task_name is None:
            #     task_name = "default_payload"
            # session.log(f"task environment: {task_name}")
            task_name = "default_payload"

            # create work directory
            session.log(f"creating task directory: /{task_name}")
            task_path = Path(f"/{task_name}")
            if task_path.exists() and task_path.is_dir():
                shutil.rmtree(task_path)
            task_path.mkdir(parents=True)

            windows_default_payload = Path(
                f"{script_dir}/../resources/windows_default_payload.ps1")
            payload = windows_default_payload.read_text()

            # result = run_remote(session, default_payload)
            result = run_remote(session, payload)
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
