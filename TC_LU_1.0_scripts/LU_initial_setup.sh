#!/bin/bash

export SNPE_DIR='/home/delta/Qualcomm/snpe-1.66.0.3729'
export ADB_SERIAL='421F999'

# Upgade System
adb devices

adb -s $ADB_SERIAL wait-for-device shell "apt update && apt upgrade -y"
adb -s $ADB_SERIAL wait-for-device shell "apt install -y apt-utils git gcc iptables qt5-default qtwayland5 qtbase5-private-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgstreamer-plugins-bad1.0-dev gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-doc gstreamer1.0-tools gstreamer1.0-x gstreamer1.0-alsa gstreamer1.0-gl gstreamer1.0-gtk3 gstreamer1.0-qt5 gstreamer1.0-pulseaudio"
adb -s $ADB_SERIAL wait-for-device shell "cp /lib/aarch64-linux-gnu/libc.so.6 /lib/libc.so.6"
adb -s $ADB_SERIAL wait-for-device reboot
timeout 120 adb wait-for-device

# Copy SNPE runtime to device
adb -s $ADB_SERIAL push $SNPE_DIR/bin/aarch64-ubuntu-gcc7.5/snpe-net-run /usr/bin
adb -s $ADB_SERIAL push $SNPE_DIR/bin/aarch64-ubuntu-gcc7.5/snpe-parallel-run /usr/bin
adb -s $ADB_SERIAL push $SNPE_DIR/bin/aarch64-ubuntu-gcc7.5/snpe-platform-validator /usr/bin
adb -s $ADB_SERIAL push $SNPE_DIR/bin/aarch64-ubuntu-gcc7.5/snpe-throughput-net-run /usr/bin

# Give Runtime run permission
adb -s $ADB_SERIAL shell chmod +x /usr/bin/snpe-net-run
adb -s $ADB_SERIAL shell chmod +x /usr/bin/snpe-parallel-run
adb -s $ADB_SERIAL shell chmod +x /usr/bin/snpe-platform-validator
adb -s $ADB_SERIAL shell chmod +x /usr/bin/snpe-throughput-net-run

# Copy essential libraries
adb -s $ADB_SERIAL shell mkdir -p /data/snpe_libs

adb -s $ADB_SERIAL push $SNPE_DIR/lib/aarch64-ubuntu-gcc7.5/libPlatformValidatorShared.so /data/snpe_libs
adb -s $ADB_SERIAL push $SNPE_DIR/lib/aarch64-ubuntu-gcc7.5/libSNPE.so /data/snpe_libs
adb -s $ADB_SERIAL push $SNPE_DIR/lib/aarch64-ubuntu-gcc7.5/libcalculator.so /data/snpe_libs
adb -s $ADB_SERIAL push $SNPE_DIR/lib/aarch64-ubuntu-gcc7.5/libhta.so /data/snpe_libs
adb -s $ADB_SERIAL push $SNPE_DIR/lib/aarch64-ubuntu-gcc7.5/libsnpe_dsp_domains_v2.so /data/snpe_libs

adb -s $ADB_SERIAL push $SNPE_DIR/lib/dsp/libcalculator_skel.so /data/snpe_libs
adb -s $ADB_SERIAL push $SNPE_DIR/lib/dsp/libsnpe_dsp_v66_domains_v2_skel.so /data/snpe_libs

adb -s $ADB_SERIAL shell cp /data/snpe_libs/libcalculator.so /usr/lib
adb -s $ADB_SERIAL shell cp /data/snpe_libs/libSNPE.so /usr/lib
adb -s $ADB_SERIAL shell cp /data/snpe_libs/libhta.so /usr/lib
adb -s $ADB_SERIAL shell cp /data/snpe_libs/libsnpe_dsp_domains_v2.so /usr/lib

# Validate all components are avaliable
adb -s $ADB_SERIAL shell 'export ADSP_LIBRARY_PATH="/data/snpe_libs;/system/lib/rfsa/adsp;/system/vendor/lib/rfsa/adsp;/dsp" && snpe-platform-validator --runtime all --debug'

# Enable root SSH login and Change Password
#adb -s $ADB_SERIAL shell "echo 'root:Delta999' | chpasswd"
#adb -s $ADB_SERIAL shell "sed -i 's/\#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config"
#adb -s $ADB_SERIAL shell 'systemctl restart sshd'

# Check Current IP
adb -s $ADB_SERIAL shell 'ifconfig | grep inet'

# Get sample-apps-for-Qualcomm-Robotics-RB5-platform from Github
adb -s $ADB_SERIAL shell 'mkdir /data/sample-apps-for-Qualcomm-Robotics-RB5-platform && git clone https://github.com/quic/sample-apps-for-Qualcomm-Robotics-RB5-platform.git /data/sample-apps-for-Qualcomm-Robotics-RB5-platform'
# Build RB5-Information(Device-info) Sample
adb -s $ADB_SERIAL shell 'cd /data/sample-apps-for-Qualcomm-Robotics-RB5-platform/Device-info && mkdir bin && cd src && make && chmod +x ../bin/qrb5165_info && cp ../bin/qrb5165_info /usr/bin'
adb -s $ADB_SERIAL shell qrb5165_info
# Build RB5-Platform(GPIO-samples) Sample
adb -s $ADB_SERIAL shell 'cd /data/sample-apps-for-Qualcomm-Robotics-RB5-platform/GPIO-samples && mkdir bin && cd src && make && chmod +x ../bin/qrb5165_platform && cp ../bin/qrb5165_platform /usr/bin'
adb -s $ADB_SERIAL shell qrb5165_platform -led green 255
# Build WIFI-On-Boarding Sample
adb -s $ADB_SERIAL shell 'cd /data/sample-apps-for-Qualcomm-Robotics-RB5-platform/WIFI-OnBoarding/wifi && gcc wifi.c -o wifi && chmod +x wifi && cp wifi /usr/bin'
# adb -s $ADB_SERIAL shell wifi

adb -s $ADB_SERIAL wait-for-device tcpip 5555
adb -s $ADB_SERIAL wait-for-device root

echo "(!!) Done!"




