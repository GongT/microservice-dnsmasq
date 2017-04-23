#!/bin/sh

set -e
set -x

SERVICE_PID_FILE=/tmp/dnsmasq.pid
STORAGE_ROOT=/storage/persist
RESOLVERS_ROOT="${STORAGE_ROOT}/resolvers"
RESOLV_FILE="${RESOLVERS_ROOT}/resolv.conf"
HOSTS_FILE="${RESOLVERS_ROOT}/host-file"

# prepare
mkdir -p ${STORAGE_ROOT}/dnsmasq.d \
	${STORAGE_ROOT}/extra.d \
	${RESOLVERS_ROOT}/
if [ ! -e ${RESOLV_FILE} ]; then
	touch ${RESOLV_FILE}
fi
if [ ! -e ${HOSTS_FILE} ]; then
	touch ${HOSTS_FILE}
fi

if [ ! -e "${RESOLV_FILE}" ]; then
	cat /etc/resolv.conf | \
		grep -vE "nameserver\s+192\.168\." | \
		grep -vE "nameserver\s+172\.17\." | \
		grep -vE "nameserver\s+10\." | \
		grep -vE "nameserver\s+127\." | \
		grep -vE "^search" | \
		grep -vE "^options" | \
		tee ${RESOLV_FILE}
fi

echo -n '' > "${SERVICE_PID_FILE}"
#prepare end

function service_died {
	if [ "${RESTARTING}" == "yes" ]; then
		return 0
	fi
	
	finish 127
}

function watch { # what_file kill_signal
	bash "./watcher.sh" "$@"
}

( watch 2 "${STORAGE_ROOT}/dnsmasq.d" "${STORAGE_ROOT}/extra.d" ) &
( watch 1 "${RESOLVERS_ROOT}" ) &

sleep .5

while [ "${RESTARTING}" == "yes" ]
do
	RESTARTING=
	
	dnsmasq --log-facility=- --port=53 --keep-in-foreground &
	
	echo -n $! >/tmp/dnsmasq.pid
	echo "dnsmasq running: $(<${SERVICE_PID_FILE})"
	
	RET=127
	wait $(<${SERVICE_PID_FILE})
	RET=$?
	echo -n >/tmp/dnsmasq.pid
	
	if [ "${RESTARTING}" == "yes" ]; then
		echo "dnsmasq will restart"
	fi
done

echo "dnsmasq quited... (code ${RET})"
