FROM python:alpine3.10

COPY . /app
COPY --chmod=755 entrypoint.sh /app
WORKDIR /app
RUN pip install -r requirements.txt
EXPOSE 5000
ENTRYPOINT ["/app/entrypoint.sh"]