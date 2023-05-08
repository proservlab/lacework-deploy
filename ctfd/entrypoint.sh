#!/bin/sh

# Run the original entrypoint command from the CTFd Docker image
/opt/CTFd/docker-entrypoint.sh "$@" &

# Wait for the CTFd web server to be available
until python -c "import requests; requests.get('http://localhost:8000')" 2>/dev/null; do
  echo "Waiting for CTFd web server to be available..."
  sleep 5
done
echo "CTFd web server is available."

# Create admin user
/opt/CTFd/CTFd/cli/users.py create --name admin --email admin@example.com --password mysecurepassword --type admin

# Generate and save API token
/bin/sh -c "echo 'from CTFd.models import Users; print(Users.query.filter_by(email=\"admin@example.com\").first().get_api_token())' | flask shell" > /api_tokens/admin_token.txt

# Keep the container running
tail -f /dev/null
