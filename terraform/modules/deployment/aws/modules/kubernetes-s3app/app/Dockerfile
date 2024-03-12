FROM python:3.10.0-slim

RUN apt-get update \
    && apt-get install curl -y \
    # && curl -LJ https://github.com/GoogleCloudPlatform/gcsfuse/releases/download/v1.4.1/gcsfuse_1.4.1_amd64.deb -o /tmp/gcsfuse.deb \
    # && apt-get install -y /tmp/gcsfuse.deb \
    && curl -LJ https://s3.amazonaws.com/mountpoint-s3-release/1.4.0/x86_64/mount-s3-1.4.0-x86_64.deb -o /tmp/mount-s3.deb \
    && apt-get install -y /tmp/mount-s3.deb \
    # && curl -LJ https://github.com/Azure/azure-storage-fuse/releases/download/blobfuse2-2.2.0/blobfuse2-2.2.0-Debian-11.0.x86_64.deb -o /tmp/blobfuse.deb \
    # && apt-get install -y /tmp/blobfuse.deb \
    && rm -rf /var/lib/apt/lists/*

COPY . /app
COPY --chmod=755 entrypoint.sh /app
WORKDIR /app
RUN pip install -r requirements.txt
EXPOSE 80
ENTRYPOINT ["/app/entrypoint.sh"]