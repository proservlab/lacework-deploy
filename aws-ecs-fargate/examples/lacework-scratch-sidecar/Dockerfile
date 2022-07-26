FROM lacework/datacollector:latest-sidecar as agent
COPY --chmod=755 lacework-sidecar-minimal.sh /var/lib/lacework-backup/lacework-sidecar-minimal.sh

FROM golang:alpine AS build
RUN apk --no-cache add tzdata
RUN apk --no-cache add ca-certificates
RUN apk update && apk add build-base

FROM scratch

# setup for lacework datacollector
COPY --from=build /etc/passwd /etc/passwd
COPY --from=build /etc/group /etc/group
COPY --from=build /home /home
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /etc/issue /etc/issue
COPY --from=build /etc/os-release /etc/os-release
COPY --from=build /bin/sh /bin/sh
COPY --from=build /bin/cat /bin/cat
COPY --from=build /bin/touch /bin/touch
COPY --from=build /bin/mkdir /bin/mkdir
COPY --from=build /bin/sleep /bin/sleep
COPY --from=build /bin/cp /bin/cp
COPY --from=build /bin/chmod /bin/chmod
COPY --from=build /usr/bin/tail /usr/bin/tail
COPY --from=build /lib/ld-musl-x86_64.so.1 /lib/
COPY --from=agent /var/lib/lacework-backup /var/lib/lacework-backup

# expose additional volumes for scratch - mounted as sidecar
VOLUME [ "/var/lib/lacework-backup" ]
VOLUME [ "/bin" ]
VOLUME [ "/usr/bin" ]
VOLUME [ "/home" ]
VOLUME [ "/etc/ssl/certs" ]
VOLUME [ "/lib" ]

CMD exec /bin/sh -c "sleep 5"