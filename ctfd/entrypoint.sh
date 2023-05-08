#!/bin/sh

# Run the original entrypoint command from the CTFd Docker image
/opt/CTFd/docker-entrypoint.sh "$@" &

# # Wait for the CTFd web server to be available
# until python -c "import requests; requests.get('http://localhost:8000/setup')" 2>/dev/null; do
#   echo "Waiting for CTFd web server to be available..."
#   sleep 5
# done
# echo "CTFd web server is available."

# # Create admin user
# /opt/CTFd/CTFd/cli/users.py create --name admin --email admin@example.com --password mysecurepassword --type admin
# 8ffe2a73987138c6d3e93e008dfa84b16792d218bda1be84f01618f1a65833a4
# # Generate and save API token
# /bin/sh -c "echo 'from CTFd.models import Users; print(Users.query.filter_by(email=\"admin@example.com\").first().get_api_token())' | flask shell" > /api_tokens/admin_token.txt

# Keep the container running
wait
