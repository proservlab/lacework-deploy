#!/usr/bin/env python3
import os
from pwncat.util import console
import pwncat.manager
import signal
import sys
from pathlib import Path
import argparse

parser = argparse.ArgumentParser(description='reverse shell listener')
parser.add_argument('--port', dest='port', type=int,
                    default=4444, help='listen port')

args = parser.parse_args()


def signal_handler(sig, frame):
    print('Interrupt caught...')
    session_lock = Path("/tmp/pwncat_session.lock")
    if session_lock.exists():
        session_lock.unlink()
    sys.exit(0)


def new_session(session: pwncat.manager.Session):
    # Returning false causes the session to be removed immediately
    session.log("new session")
    session.run("responder")
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
            port=args.port,
            platform="linux",
            established=new_session
        )

    manager.log("listener created")

    while listener.is_alive():
        pass
