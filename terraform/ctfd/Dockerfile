FROM ctfd/ctfd:latest

COPY entrypoint.sh /opt/CTFd/custom-entrypoint.sh
USER root
RUN chown ctfd:ctfd /opt/CTFd/custom-entrypoint.sh
RUN chmod +x /opt/CTFd/custom-entrypoint.sh
RUN mkdir /home/ctfd
RUN chown ctfd:ctfd /home/ctfd
USER 1001

ENTRYPOINT ["/opt/CTFd/custom-entrypoint.sh"]
