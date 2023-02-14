# Lacework agent: adding a build stage

ARG DcVersion=*
FROM lacework/datacollector:6.3.0-sidecar AS agent-build-image

FROM ubuntu:latest as lw-agent-provider
ARG DcVersion
COPY --from=agent-build-image /var/lib/lacework-backup/${DcVersion}/datacollector /var/lib/lacework/datacollector
RUN chmod +x /var/lib/lacework/datacollector

# Use the official lightweight Python image.
# https://hub.docker.com/_/python
FROM python:3.10-slim

# Lacework agent: copying the agent binary
COPY --from=lw-agent-provider /var/lib/lacework/datacollector /var/lib/lacework/datacollector

# Allow statements and log messages to immediately appear in the Knative logs
ENV PYTHONUNBUFFERED True

# Copy source code to the container image.
ENV APP_HOME /app
WORKDIR $APP_HOME
COPY --chmod=755 ./src/ ./

# Install production dependencies.
RUN pip install --no-cache-dir -r requirements.txt

# Start the agent and the application
CMD ["/app/run.sh"]
