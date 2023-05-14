#!/bin/sh

# Run the original entrypoint command from the CTFd Docker image in the background
/opt/CTFd/docker-entrypoint.sh "$@" &

# Wait for the CTFd web server to be available
until python -c "import requests; requests.get('http://localhost:8000')" 2>/dev/null; do
  echo "Waiting for CTFd web server to be available..."
  sleep 5
done
echo "CTFd web server is available."

# Keep the container running
wait
