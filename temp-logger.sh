#!/bin/bash

DIGIEXEC=/usr/bin/digitemp_DS9097

P0_CONF=digitemprc-usb0
P1_CONF=digitemprc-usb1

P0_USB=/dev/ttyUSB0
P1_USB=/dev/ttyUSB1

# -q = no copyright info
# -t sensor id for given config
PARAMS="-q -t 0"

DATELOGFORMAT="%Y-%m-%d %H:%M:%S"
LOGDATE=$(date +"%Y%m%d_%H%M")

#LOGFILE="logs/${LOGDATE}_pitemplog.csv"
LOG_FOLDER="/home/pi/pi-temp-log"
LOGFILE="${LOG_FOLDER}/${LOGDATE}_pitemplog.csv"

LOGINTERVALSECONDS=598
PUSH_TO_GITHUB=

# For handling exit/sigint
EXIT=

# Script folder
SCRIPT_FOLDER="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null 2>&1 && pwd )"

source $SCRIPT_FOLDER/lib-github-log-send.sh

function printUsage() {
	echo "Usage: $0 [-tnsv] [-i <seconds>]"
	echo "	-i	Interval in seconds."
	echo "		Default is 598 (sensor reading takes approx. 2 seconds)"
	echo "	-t	One sample to console"
	echo "	-n	Samples only to console, no logfile"
	echo "	-s	Activate GitHub commit of log (if network available)"
	echo "	-v	Set verbose flag, bash -x"
	exit 0
}

function printLogHeader() {
	HEADER="time;sensor1;sensor2"

	echo $HEADER

	if [ ! -z $LOGFILE ]; then
		# Always create new file
		echo $HEADER > $LOGFILE
	fi	
}

function doLog() {
	DATE=$(date +"$DATELOGFORMAT")
	T0=$($DIGIEXEC -c $P0_CONF -s $P0_USB $PARAMS)
	T1=$($DIGIEXEC -c $P1_CONF -s $P1_USB $PARAMS)
	
	LOG="${DATE};${T0};${T1}"

	echo $LOG

	if [ ! -z $LOGFILE ]; then
		echo $LOG >> $LOGFILE
	fi
}

function handleSigInt() {
	echo -e "\nSIGINT caught - finishing up.."
	EXIT=yep
}


while getopts ":ntsvi:" OPTS; do
	case $OPTS in
	v)
		set -x
		;;
	n)
		unset LOGFILE
		;;
	t)
		unset LOGFILE
		printLogHeader
		doLog
		exit 1
		;;
	i)
		LOGINTERVALSECONDS=$OPTARG
		;;
	s)
		PUSH_TO_GITHUB=yep
		;;
	\?)
		printUsage
		;;
	:)
		echo "ERROR: Option -$OPTARG requires an argument"
		printUsage
		;;
	esac
done

##########################################
#               Main Loop                #
##########################################

echo "Starting PI temperature logger"
echo "** Interval (s):	$LOGINTERVALSECONDS"
echo -n "** Logfile:		"

if [ -z $LOGFILE ]; then
	echo "<none>"
else
	echo $LOGFILE
fi

echo

if [ ! -z $PUSH_TO_GITHUB ]; then
	# Fork github-sender
	initGitHubSend ${LOG_FOLDER} &
	echo
	sleep 1
fi

trap handleSigInt SIGINT SIGTERM
printLogHeader

while `true`; do
	doLog
	sleep $LOGINTERVALSECONDS

	if [ ! -z $EXIT ]; then
		break
	fi
done

echo -n "Logging ended."

if [ ! -z $LOGFILE ]; then
	echo " Logfile '$LOGFILE' contains `sed 1d $LOGFILE | wc -l` row(s) with temperature data."
else
	echo
fi

exit 0
