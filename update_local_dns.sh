#!/usr/bin/env bash

cat /etc/resolve.conf > ./etc/resolv.dnsmasq

if which NetworkManager &>/dev/null ; then
	echo "you have NetworkManager installed, please set network default nameserver to 127.0.0.1">&2
fi
