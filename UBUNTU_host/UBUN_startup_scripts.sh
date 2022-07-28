#!/bin/bash

adb devices

adb shell "apt update && apt upgrade -y"
adb shell "cp /usr/lib/aarch64-linux-gnu/libc.so /usr/lib"
adb reboot
timeout 120 adb wait-for-device