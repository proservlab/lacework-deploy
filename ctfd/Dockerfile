FROM ctfd/ctfd:latest

COPY entrypoint.sh /entrypoint.sh
USER root
RUN chmod +x /entrypoint.sh
USER 1001

ENTRYPOINT ["/entrypoint.sh"]
