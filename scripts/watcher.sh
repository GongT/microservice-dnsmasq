#!/bin/sh

set -x

KILL_SIGNAL=$1 # SIGHUP(1) or SIGINT(2)
shift
WATCH=("$@")

PID=$$

while true
do
	echo "start watch ${WATCH}: "
	inotifywatch \
		"--recursive" \
		"--event" "modify" \
		"--event" "create" \
		"--event" "delete" \
		"--event" "move" \
		"${WATCH[@]}"
	
	RET=$?
	
	echo "    ${WATCH} watch return: ${RET}"
	if [ "${RET}" -eq 0 ]; then
		echo "    kill dnsmasq with signal: ${KILL_SIGNAL}"
		killall dnsmasq --signal ${KILL_SIGNAL}
	elif [ "${RET}" -eq 1 ]; then
		echo "    Error !"
		echo "    kill parent process ($PPID) with SIGKILL"
		kill -9 $PPID
	fi
done

