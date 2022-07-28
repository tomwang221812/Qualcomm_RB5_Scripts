#!/bin/bash

export SNPE_DIR='/home/tomwang/snpe-1.64.0.3605'

# Upgade System
adb devices

adb shell "apt update && apt upgrade -y"
adb shell "cp /lib/aarch64-linux-gnu/libc.so.6 /lib/libc.so.6"
adb reboot
timeout 120 adb wait-for-device

# Copy SNPE runtime to device
adb push $SNPE_DIR/bin/aarch64-ubuntu-gcc7.5/snpe-net-run /usr/bin
adb push $SNPE_DIR/bin/aarch64-ubuntu-gcc7.5/snpe-parallel-run /usr/bin
adb push $SNPE_DIR/bin/aarch64-ubuntu-gcc7.5/snpe-platform-validator /usr/bin
adb push $SNPE_DIR/bin/aarch64-ubuntu-gcc7.5/snpe-throughput-net-run /usr/bin

# Give Runtime run permission
adb shell chmod +x /usr/bin/snpe-net-run
adb shell chmod +x /usr/bin/snpe-parallel-run
adb shell chmod +x /usr/bin/snpe-platform-validator
adb shell chmod +x /usr/bin/snpe-throughput-net-run

# Copy essential libraries
adb shell mkdir -p /data/snpe_libs

adb push $SNPE_DIR/lib/aarch64-ubuntu-gcc7.5/libPlatformValidatorShared.so /data/snpe_libs
adb push $SNPE_DIR/lib/aarch64-ubuntu-gcc7.5/libSNPE.so /data/snpe_libs
adb push $SNPE_DIR/lib/aarch64-ubuntu-gcc7.5/libcalculator.so /data/snpe_libs
adb push $SNPE_DIR/lib/aarch64-ubuntu-gcc7.5/libhta.so /data/snpe_libs
adb push $SNPE_DIR/lib/aarch64-ubuntu-gcc7.5/libsnpe_dsp_domains_v2.so /data/snpe_libs

adb push $SNPE_DIR/lib/dsp/libcalculator_skel.so /data/snpe_libs
adb push $SNPE_DIR/lib/dsp/libsnpe_dsp_v66_domains_v2_skel.so /data/snpe_libs

adb shell cp /data/snpe_libs/libcalculator.so /usr/lib
adb shell cp /data/snpe_libs/libhta.so /usr/lib
adb shell cp /data/snpe_libs/libsnpe_dsp_domains_v2.so /usr/lib

# Validate all components are avaliable
adb shell 'export ADSP_LIBRARY_PATH="/data/snpe_libs;/system/lib/rfsa/adsp;/system/vendor/lib/rfsa/adsp;/dsp" && snpe-platform-validator --runtime all --debug'

# Enable root SSH login and Change Password
adb shell "echo 'root:Delta999' | chpasswd"
adb shell "sed -i 's/\#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config"
adb shell 'systemctl restart sshd'

# Check Current IP
adb shell 'ifconfig | grep inet'

echo "(!!) Done!"




