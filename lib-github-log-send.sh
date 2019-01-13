#!/bin/bash

GIT=/usr/bin/git
PING=/bin/ping
WC=/usr/bin/wc
GREP=/bin/grep

SLEEP_NO_NET=5
SLEEP_NET=600
SLEEP_NET_NO_CHANGE=30

function initGitHubSend() {
	# Directory to check is passed as an argument
	GH_DIRECTORY=$1

	echo "Init of GitHub sender, monitoring folder '${GH_DIRECTORY}."
	echo "Sleeping 10 seconds before starting to check for changes"
	sleep 10

	# Make sure we have a clean repo
	cd $GH_DIRECTORY
	$GIT fetch --all > /dev/null 2>&1
	$GIT reset --hard origin/master > /dev/null 2>&1

	COMMIT_COUNT=0

	# Loop for checking network and sending logs
	while `true`; do

		$PING -c 1 github.com > /dev/null 2>&1
		RETVAL=$?

		if [ $RETVAL -ne 0 ]; then
			# No network, sleep and try again
			sleep $SLEEP_NO_NET

		else
			# Network, send logs if available
			# Check if repo is clean or has stuff to push
			IS_CLEAN=$( $GIT status | $GREP clean | $WC -l )

			if [ $IS_CLEAN -eq 1 ]; then
				# Clean, sleep swiftly and check again
				sleep $SLEEP_NET_NO_CHANGE

			else
				# Stuff to commit/push
				$GIT add -A > /dev/null 2>&1
				
				let "COMMIT_COUNT += 1"
				$GIT commit -m "Log commit #${COMMIT_COUNT}" > /dev/null 2>&1
				$GIT push > /dev/null 2>&1

				echo "Log pushed, exit code: $?"

				#sleep $SLEEP_NET
				sleep $SLEEP_NET_NO_CHANGE
			fi
		fi
	done
}
