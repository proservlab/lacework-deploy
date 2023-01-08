FROM python:3.9-slim

RUN apt-get update \
    && apt-get install curl -y \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /app
WORKDIR /app

# We copy just the requirements.txt first to leverage Docker cache

COPY requirements.txt /app
RUN pip install -r requirements.txt

COPY . /app
COPY --chmod=777 bootstrap.sh /app/bootstrap.sh
EXPOSE 5000
ENTRYPOINT ["/app/bootstrap.sh"]