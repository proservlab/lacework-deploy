FROM python:3.9-slim

RUN apt-get update \
    && apt-get install curl -y \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install -U pip setuptools wheel setuptools_rust jinja2 jc 
RUN python3 -m pip install -U pwncat-cs 

WORKDIR /app
COPY ./responder.py ./plugins/responder.py
COPY ./listener.py ./
COPY ./*.sh ./resources

COPY --chmod=755 entrypoint.sh /app

EXPOSE 80
ENTRYPOINT ["/app/entrypoint.sh"]