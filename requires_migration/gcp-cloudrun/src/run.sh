#!/bin/bash

# Start Lacework agent in the background
/var/lib/lacework/datacollector &
touch /var/log/lacework/datacollector.log
tail -f /var/log/lacework/datacollector.log &

# Start your application
# Run the web service on container startup. Here we use the 
# gunicorn webserver, with one worker process and 8 threads.
# Timeout is set to 0 to disable the timeouts of the workers to 
# allow Cloud Run to handle instance scaling.
gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 main:app
