#!/bin/bash

set -euxo pipefail

echo "Enter the sudo password: "
read PW

echo "(II) User Home Dir: $HOME"
echo "(II) Crrent Dir: $PWD"

export LATEST_BOOTLOADER_URL=$(curl -w "%{url_effective}\n" -I -L -s -S http://snapshots.linaro.org/96boards/qrb5165-rb5/linaro/rescue/latest -o /dev/null)
export LATEST_BOOTLOADER_VERSION_WITH_TAIL=${LATEST_BOOTLOADER_URL##*rescue/}
export LATEST_BOOTLOADER_VERSION=${LATEST_BOOTLOADER_VERSION_WITH_TAIL%/}
export LATEST_AOSP_URL=$(curl -w "%{url_effective}\n" -I -L -s -S http://snapshots.linaro.org/96boards/qrb5165-rb5/linaro/aosp-master/latest -o /dev/null)
export LATEST_AOSP_VERSION_WITH_TAIL=${LATEST_AOSP_URL##*aosp-master/}
export LATEST_AOSP_VERSION=${LATEST_AOSP_VERSION_WITH_TAIL%/}

export AOSP_DIR=${PWD}/AOSP_${LATEST_AOSP_VERSION}

echo "(II) Create and enter Dir: $PWD"
mkdir -p $AOSP_DIR
cd $AOSP_DIR

echo "[Download] (1/5) Download and Unzip latest AOSP bootloader ..."
echo $PW | sudo wget http://snapshots.linaro.org/96boards/qrb5165-rb5/linaro/rescue/latest/rb5-bootloader-ufs-aosp-${LATEST_BOOTLOADER_VERSION}.zip
unzip rb5-bootloader-ufs-aosp-${LATEST_BOOTLOADER_VERSION}.zip
echo "[Download] (2/5) Download userdata.img ..."
echo $PW | sudo wget http://snapshots.linaro.org/96boards/qrb5165-rb5/linaro/aosp-master/latest/userdata.img
echo "[Download] (3/5) Download super.img ..."
echo $PW | sudo wget http://snapshots.linaro.org/96boards/qrb5165-rb5/linaro/aosp-master/latest/super.img
echo "[Download] (4/5) Download vendor_boot.img ..."
echo $PW | sudo wget http://snapshots.linaro.org/96boards/qrb5165-rb5/linaro/aosp-master/latest/vendor_boot.img
echo "[Download] (5/5) Download boot.img ..."
echo $PW | sudo wget http://snapshots.linaro.org/96boards/qrb5165-rb5/linaro/aosp-master/latest/boot.img

echo "Please get your device into fastboot!!! (You only have 120secs)"
timeout 120 fastboot wait-for-device
fastboot devices

echo $PW | sudo chmod +x ./flashall
echo $PW | sudo ./flashall
echo "[Bootloader Flash] Start to flash Bootloader"
cd rb5-bootloader-ufs-aosp-${LATEST_BOOTLOADER_VERSION}

cd $AOSP_DIR
fastboot devices
echo "[Fastboot Flash] (1/4) Start to flash ${PWD}/userdata.img"
fastboot flash userdata userdata.img
echo "[Fastboot Flash] (2/4) Start to flash ${PWD}/super.img"
fastboot flash super super.img
echo "[Fastboot Flash] (3/4) Start to flash ${PWD}/vendor_boot.img"
fastboot flash vendor_boot vendor_boot.img
echo "[Fastboot Flash] (4/4) Start to flash ${PWD}/boot.img"
fastboot flash boot boot.img

echo "(II) Try to reboot device"
fastboot reboot

echo "Wait for device connect... (Timeout 120 sec)"
timeout 120 adb wait-for-device
sleep 30s

echo "Restart ADB as root"
adb devices
adb root
sleep 5s
echo "Disable verity"
adb disable-verity
sleep 5s
echo "Reboot device"
adb reboot
sleep 5s
echo "Wait device"
adb wait-for-device
echo "Restart ADB as root"
adb root
sleep 5s
echo "Remount device"
adb remount

