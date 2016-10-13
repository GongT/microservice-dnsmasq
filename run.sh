#!/usr/bin/env bash

PARENT=$$

function common_kill {
	kill -s 1 -- "$@" &>/dev/null
}
function finish {
	echo "script quit !!!"
	local JOBS=$(jobs -p)
	if [ -n "${JOBS}" ]; then
		echo "stopping jobs:" ${JOBS}
		local PID_FILE=
		for PID_FILE in "${JOBS[@]}"
		do
			if is_running ${PID_FILE} ; then
				echo "${PID_FILE} - killing"
				common_kill ${PID_FILE}
			else
				echo "${PID_FILE} - not running"
			fi
		done
		kill -- -${PARENT}
		wait
	fi
	echo "script exit with code ${1-0}"
	exit ${1-0}
}

if [ -z "${IS_DOCKER}" ] ; then
	HOST_TO_WATCH=/etc/hosts
else
	HOST_TO_WATCH=/host_etc/hosts
fi

function is_running {
	stat /proc/${1}/exe &>/dev/null
}

trap finish EXIT

function watch { # watch_id events callback file[s]
	local ARGS="$@"
	local WATCHID=$1
	local EVENTS=$2
	local CALLBACK=$3
	local FILE_TO_WATCH=$4
	
	local PID_FILE="/tmp/${WATCHID}.pid"
	local FIFO="/tmp/${WATCHID}.output"
	
	if [ -f ${PID_FILE} ]; then
		if is_running $(<"${PID_FILE}") ; then
			echo "kill watcher ${PID_FILE}"
			common_kill $(<"${PID_FILE}")
		fi
	fi
	
	touch ${PID_FILE}
	
	function READ_OUTPUT {
		local IN_PID=$1
		cat ${FIFO} | while read LINE
		do
			echo $LINE
			if echo ${LINE} | grep -qiE "${EVENTS//,/\|}" ; then
				${CALLBACK} ${LINE}
			elif echo ${LINE} | grep -qiE "delete_self|unmount|move_self" ; then
				echo "file removed: ${LINE}"
				unlink ${FIFO}
				common_kill "${IN_PID}"
				break
			fi
		done
	}
	
	while true
	do
		[ ! -e "${FILE_TO_WATCH}" ] && echo "no file (will poll stat): ${FILE_TO_WATCH}"
		while [ ! -e "${FILE_TO_WATCH}" ]; do sleep 1; done
		
		echo "watching: ${FILE_TO_WATCH}"
		
		[ -e ${FIFO} ] && unlink ${FIFO}
		mkfifo ${FIFO}
		
		inotifywait -e "${EVENTS},delete_self,unmount,move_self" \
					-m --format '%w %e' \
					"${FILE_TO_WATCH}" \
					-q -o ${FIFO} &
		local IN_PID=$!
		READ_OUTPUT ${IN_PID}
		
		echo "watch finished with $?"
		sleep .5
	done </dev/null &
	echo $! >${PID_FILE}
}

RESTARTING=yes
SERVICE_PID_FILE=/tmp/dnsmasq.pid
echo -n >/tmp/dnsmasq.pid
function service_died {
	if [ "${RESTARTING}" == "yes" ]; then
		return 0
	fi
	
	finish 127
}

function restart_dnsmasq {
	echo "killing dnsmasq($(<${SERVICE_PID_FILE}))..."
	if [ -z "$(<${SERVICE_PID_FILE})" ]; then
		echo "error: service not even started..."
		return 2
	fi
	RESTARTING=yes
	kill -s 1 -- "$(<${SERVICE_PID_FILE})"
	# SIGHUB will reload dnsmasq, not kill it, this is an hidden api. not everything reload
	echo "killed dnsmasq($(<${SERVICE_PID_FILE}))!"
}

# watch 2 "delete,delete_self" "service_died" /tmp/xxx


if [ "${IS_DOCKER}" == 'yes' ]; then
	echo "working in docker"
	HOST_FILE=/host_etc/hosts
else
	echo "working on host"
	HOST_FILE=/etc/hosts
fi

watch 1 "modify" "restart_dnsmasq" ${HOST_FILE}

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
