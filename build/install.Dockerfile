VOLUME /config
RUN apk -U add dnsmasq inotify-tools bash grep sed
RUN apk -U add syslog-ng
