#!/bin/bash

set -euxo pipefail

echo "(II) User Home Dir: $HOME"
echo "(II) Crrent Dir: $PWD"

echo "(1/4) Start to flash ${PWD}/userdata.img"
fastboot flash userdata userdata.img
echo "(2/4) Start to flash ${PWD}/super.img"
fastboot flash super super.img
echo "(3/4) Start to flash ${PWD}/vendor_boot.img"
fastboot flash vendor_boot vendor_boot.img
echo "(4/4) Start to flash ${PWD}/boot.img"
fastboot flash boot boot.img

echo "(II) Try to reboot device"
fastboot reboot

echo "Wait for device connect... (Timeout 120 sec)"
timeout 120 adb wait-for-device
