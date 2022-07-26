FROM ubuntu:18.04
RUN apt-get update -y
RUN apt-get install -y python-pip python-dev build-essential
COPY . /app
COPY --chmod=755 entrypoint.sh /app
WORKDIR /app
RUN pip install -r requirements.txt
ENTRYPOINT ["entrypoint.sh"]