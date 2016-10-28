VOLUME /config
RUN [ -n "${IS_CHINA}" ] && \
 echo -e "http://mirrors.aliyun.com/alpine/v3.4/main\nhttp://mirrors.aliyun.com/alpine/v3.4/community" > /etc/apk/repositories ; \
 apk -U add dnsmasq inotify-tools bash grep
