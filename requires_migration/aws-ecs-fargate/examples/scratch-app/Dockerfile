# FROM lacework/datacollector:latest-sidecar AS agent
# RUN cp /var/lib/lacework-backup/*/datacollector-musl /datacollector_alpine
# RUN cp /var/lib/lacework-backup/*/datacollector /datacollector_linux
# RUN chmod 755 /datacollector*


FROM golang:alpine AS build
RUN apk --no-cache add tzdata
RUN apk --no-cache add ca-certificates
WORKDIR /app
ADD prog.go /app
RUN apk update && apk add build-base
RUN cd /app && CGO_ENABLED=0 go build -ldflags="-w -s" -o prog prog.go


##################################################
# minimal scratch image v2
##################################################

FROM scratch

# staging for go app
WORKDIR /app
COPY --from=build /app/prog /app/awesome-prog
COPY --from=build /usr/share/zoneinfo /usr/share/zoneinfo
ENV TZ=UTC

# # setup for lacework datacollector
# ADD lacework-sidecar-minimal.sh .
# COPY --from=build /etc/passwd /etc/passwd
# COPY --from=build /etc/group /etc/group
# COPY --from=build /home /home
# COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
# COPY --from=build /etc/issue /etc/issue
# COPY --from=build /etc/os-release /etc/os-release
# COPY --from=build /bin/sh /bin/sh
# COPY --from=build /bin/cat /bin/cat
# COPY --from=build /bin/touch /bin/touch
# COPY --from=build /bin/mkdir /bin/mkdir
# COPY --from=build /usr/bin/tail /usr/bin/tail
# COPY --from=build /lib/ld-musl-x86_64.so.1 /lib/
# COPY --from=agent --chmod=755 /datacollector_alpine /var/lib/lacework/datacollector
# ENV LaceworkAccessToken="2032acf77969af1ed2e083434e08a8c14848d3d829b97d65fbda0873"
# ENV LaceworkVerbose=true

# ENTRYPOINT ["/app/awesome-prog"]
CMD ["/app/awesome-prog" ]