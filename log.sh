#!/bin/bash

DIGIEXEC=/usr/bin/digitemp_DS9097

P0_CONF=digitemprc-usb0
P1_CONF=digitemprc-usb1

P0_USB=/dev/ttyUSB0
P1_USB=/dev/ttyUSB1

PARAMS="-q -t 0"

T0=$($DIGIEXEC -c $P0_CONF -s $P0_USB $PARAMS)
T1=$($DIGIEXEC -c $P1_CONF -s $P1_USB $PARAMS)
echo $T0 $T1

