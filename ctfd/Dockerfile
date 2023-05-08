FROM ctfd/ctfd:latest

COPY entrypoint.sh /entrypoint.sh
USER root
RUN chmod +x /entrypoint.sh
RUN mkdir /home/ctfd
RUN chown ctfd:ctfd /home/ctfd
USER 1001

ENTRYPOINT ["/entrypoint.sh"]
