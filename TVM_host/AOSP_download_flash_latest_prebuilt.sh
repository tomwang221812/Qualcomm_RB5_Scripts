#!/bin/bash

set -euxo pipefail

echo "Enter the sudo password: "
read PW

echo "(II) User Home Dir: $HOME"
echo "(II) Crrent Dir: $PWD"

export AOSP_DIR = ${PWD}/AOSP_linaro

echo "(II) Create and enter Dir: $PWD"
mkdir -p $AOSP_DIR
cd $AOSP_DIR

echo "[Download] (1/4) Download ${PWD}/userdata.img ..."
echo $PW | sudo wget http://snapshots.linaro.org/96boards/qrb5165-rb5/linaro/aosp-master/latest/userdata.img
echo "(2/4) Download ${PWD}/super.img ..."
echo $PW | sudo wget http://snapshots.linaro.org/96boards/qrb5165-rb5/linaro/aosp-master/latest/super.img
echo "(3/4) Download ${PWD}/vendor_boot.img ..."
echo $PW | sudo wget http://snapshots.linaro.org/96boards/qrb5165-rb5/linaro/aosp-master/latest/vendor_boot.img
echo "(4/4) Download ${PWD}/boot.img ..."
echo $PW | sudo wget http://snapshots.linaro.org/96boards/qrb5165-rb5/linaro/aosp-master/latest/boot.img

echo "Please get your device into fastboot!!!"
adb reboot bootloader
timeout 120 fastboot wait-for-device

echo "[Download] (1/4) Start to flash ${PWD}/userdata.img"
fastboot flash userdata userdata.img
echo "[Download] (2/4) Start to flash ${PWD}/super.img"
fastboot flash super super.img
echo "[Download] (3/4) Start to flash ${PWD}/vendor_boot.img"
fastboot flash vendor_boot vendor_boot.img
echo "[Download] (4/4) Start to flash ${PWD}/boot.img"
fastboot flash boot boot.img

echo "(II) Try to reboot device"
fastboot reboot

echo "Wait for device connect... (Timeout 120 sec)"
timeout 120 adb wait-for-device
