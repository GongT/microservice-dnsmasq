FROM alpine

VOLUME /storage/persist /storage/share

RUN echo "http://mirrors.aliyun.com/alpine/edge/community/" > /etc/apk/repositories && \
echo "http://mirrors.aliyun.com/alpine/edge/main/" >> /etc/apk/repositories && \
apk add -U dnsmasq inotify-tools psmisc

COPY build.sh /tmp/build.sh
RUN sh /tmp/build.sh

COPY scripts /scripts

WORKDIR /scripts
ENTRYPOINT /usr/bin/bash
CMD "./run.sh"
