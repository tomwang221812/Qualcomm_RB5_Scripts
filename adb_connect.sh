#!/bin/bash

adb -s $1 wait-for-device tcpip 5555
adb -s $1 wait-for-device root
adb -s $1 wait-for-device connect $2:5555
