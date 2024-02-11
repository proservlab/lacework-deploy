FROM python:3.10-slim

RUN apt-get update \
    && apt-get install curl -y \
    && rm -rf /var/lib/apt/lists/*

RUN curl -LJ https://s3.amazonaws.com/mountpoint-s3-release/1.4.0/x86_64/mount-s3-1.4.0-x86_64.deb -o /tmp/mount-s3.deb \
    && apt-get install -y mount-s3.deb

COPY . /app
COPY --chmod=755 entrypoint.sh /app
WORKDIR /app
RUN pip install -r requirements.txt
EXPOSE 80
ENTRYPOINT ["/app/entrypoint.sh"]