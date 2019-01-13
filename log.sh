#!/bin/bash

DIGIEXEC=/usr/bin/digitemp_DS9097

P0_CONF=digitemprc-usb0
P1_CONF=digitemprc-usb1

P0_USB=/dev/ttyUSB0
P1_USB=/dev/ttyUSB1

PARAMS="-q -t 0"

DATELOGFORMAT="%Y-%m-%d %H:%M:%S"
LOGDATE=$(date +"%Y%m%d_%H%M")

LOGFILE="logs/${LOGDATE}_pitemplog.csv"

LOGINTERVALSECONDS=598

# For handling exit/sigint
EXIT=

function printUsage() {
	echo "Usage: $0 [-tnv]"
	echo "	-i	Interval in seconds."
	echo "		Default is 598 (sensor reading takes approx. 2 seconds)"
	echo "	-t	One sample to console"
	echo "	-n	Samples only to console, no logfile"
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


while getopts ":ntvi:" OPTS; do
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

trap handleSigInt SIGINT
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
	echo " Logfile '$LOGFILE' contains `wc -l $LOGFILE` row(s)."
else
	echo
fi

exit 0
