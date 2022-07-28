#!/bin/bash

set -euxo pipefail

export FASTRPC_LINARO_URL="https://git.linaro.org/landing-teams/working/qualcomm/fastrpc.git"
export FASTRPC_AOSP_URL="https://android.googlesource.com/platform/external/fastrpc"
export LIBADSPRPC_LINARO_URL="https://git.linaro.org/landing-teams/working/qualcomm/libadsprpc.git"

# Setup AOSP Source

# Setup Android NDK Environment
export ANDROID_NDK_VERSION='25.0.8775105'
export ANDROID_NDK="$HOME/Android/Sdk/ndk/$ANDROID_NDK_VERSION"
# export NDK="/mnt/c/Users/tomwa/android-ndk-r25"
# Set NDK Toolchain
export TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64
# Set this to your minSdkVersion.
export API=33

echo "(II) User Home Dir: $HOME"
echo "(II) Crrent Dir: $PWD"
echo "(II) NDK Path: $NDK"

export FASTRPC_TOP=${PWD}/FastRPC_android
export DOWNLOAD_SRC_PATH=${FASTRPC_TOP}/downloads
export MODIFIED_SRC_PATH=${FASTRPC_TOP}/modified
export BUILD_RESULTS_PATH=${FASTRPC_TOP}/results

# TOP Dirs
mkdir -p ${DOWNLOAD_SRC_PATH}
mkdir -p ${MODIFIED_SRC_PATH}
mkdir -p ${BUILD_RESULTS_PATH}

# Create Download Dirs
mkdir -p ${DOWNLOAD_SRC_PATH}/LINARO
mkdir -p ${DOWNLOAD_SRC_PATH}/AOSP

# Create Modified Dirs
mkdir -p ${MODIFIED_SRC_PATH}/LINARO
mkdir -p ${MODIFIED_SRC_PATH}/AOSP

# Create Output Dirs (64bit)
mkdir -p ${BUILD_RESULTS_PATH}/LINARO/fastrpc/aarch64/AOSP_rb5
mkdir -p ${BUILD_RESULTS_PATH}/LINARO/libadsprpc/aarch64/AOSP_rb5
mkdir -p ${BUILD_RESULTS_PATH}/AOSP/fastrpc/aarch64/AOSP_rb5

# Create Output Dirs (32bit)
mkdir -p ${BUILD_RESULTS_PATH}/LINARO/fastrpc/armv7a/AOSP_rb5
mkdir -p ${BUILD_RESULTS_PATH}/LINARO/libadsprpc/armv7a/AOSP_rb5
mkdir -p ${BUILD_RESULTS_PATH}/AOSP/fastrpc/armv7a/AOSP_rb5

# Pull from sources
echo "(II) [1/4] Cloning FastRPC from Linaro"
git clone $FASTRPC_LINARO_URL ${DOWNLOAD_SRC_PATH}/LINARO/fastrpc
echo "(II) [2/4] Cloning libadsprpc from Linaro"
git clone $LIBADSPRPC_LINARO_URL ${DOWNLOAD_SRC_PATH}/LINARO/libadsprpc
echo "(II) [3/4] Cloning FastRPC from AOSP"
git clone $FASTRPC_AOSP_URL ${DOWNLOAD_SRC_PATH}/AOSP/fastrpc

# Pull cutils lib since not it is not in the NDK
echo "(II) [4/4] Cloning libcutils from AOSP source"
git clone https://android.googlesource.com/platform/system/core ${DOWNLOAD_SRC_PATH}/core

# Copy and ready to be modified
cp --verbose -r ${DOWNLOAD_SRC_PATH}/LINARO/fastrpc ${MODIFIED_SRC_PATH}/LINARO
cp --verbose -r ${DOWNLOAD_SRC_PATH}/LINARO/libadsprpc ${MODIFIED_SRC_PATH}/LINARO
cp --verbose -r ${DOWNLOAD_SRC_PATH}/AOSP/fastrpc ${MODIFIED_SRC_PATH}/AOSP
cp --verbose -r ${DOWNLOAD_SRC_PATH}/core ${MODIFIED_SRC_PATH}
export CUTILS_INCLUDE_PATH=${MODIFIED_SRC_PATH}/core/libcutils/include

export TARGET=aarch64-linux-android # 64Bit

# Build and Modify

# Linaro FastRPC
cd ${MODIFIED_SRC_PATH}/LINARO/fastrpc
./autogen.sh

sed -i 's/-I\$(top_srcdir)\/inc/-I\$(top_srcdir)\/inc -I\$(top_srcdir)\/..\/..\/core\/libcutils\/include/' ${MODIFIED_SRC_PATH}/LINARO/fastrpc/src/Makefile.am
sed -i 's/adsprpcd_LDADD = -ldl/adsprpcd_LDADD = -ldl -llog/' ${MODIFIED_SRC_PATH}/LINARO/fastrpc/src/Makefile.am
sed -i 's/cdsprpcd_LDADD =  -ldl/cdsprpcd_LDADD = -ldl -llog/' ${MODIFIED_SRC_PATH}/LINARO/fastrpc/src/Makefile.am
sed -i 's/sdsprpcd_LDADD =  -ldl/sdsprpcd_LDADD = -ldl -llog/' ${MODIFIED_SRC_PATH}/LINARO/fastrpc/src/Makefile.am
sed -i 's/-lpthread //' ${MODIFIED_SRC_PATH}/LINARO/fastrpc/src/Makefile.am

./configure --host=$TARGET CC=$TOOLCHAIN/bin/$TARGET$API-clang

make -j$(nproc --all)

cp --verbose -r ${MODIFIED_SRC_PATH}/LINARO/fastrpc/src/.deps ${BUILD_RESULTS_PATH}/LINARO/fastrpc/aarch64/deps
cp --verbose -r ${MODIFIED_SRC_PATH}/LINARO/fastrpc/src/.libs ${BUILD_RESULTS_PATH}/LINARO/fastrpc/aarch64/libs
cp --verbose -r ${BUILD_RESULTS_PATH}/LINARO/fastrpc/aarch64/libs/*.so ${BUILD_RESULTS_PATH}/LINARO/fastrpc/aarch64/AOSP_rb5

# Linaro adsprpc
cd ${MODIFIED_SRC_PATH}/LINARO/libadsprpc
./autogen.sh

sed -i 's/-lpthread //' ${MODIFIED_SRC_PATH}/LINARO/libadsprpc/src/utils/Makefile.am
sed -i 's/-lpthread //' ${MODIFIED_SRC_PATH}/LINARO/libadsprpc/src/lib/Makefile.am

./configure --host=$TARGET CC=$TOOLCHAIN/bin/$TARGET$API-clang

make -j$(nproc --all)

cp --verbose -r ${MODIFIED_SRC_PATH}/LINARO/libadsprpc/src/lib/.libs ${BUILD_RESULTS_PATH}/LINARO/libadsprpc/aarch64/libs
cp --verbose -r ${MODIFIED_SRC_PATH}/LINARO/libadsprpc/src/utils/.libs ${BUILD_RESULTS_PATH}/LINARO/libadsprpc/aarch64/utils
cp --verbose -r ${BUILD_RESULTS_PATH}/LINARO/libadsprpc/aarch64/libs/*.so ${BUILD_RESULTS_PATH}/LINARO/libadsprpc/aarch64/AOSP_rb5
cp --verbose -r ${BUILD_RESULTS_PATH}/LINARO/libadsprpc/aarch64/utils/* ${BUILD_RESULTS_PATH}/LINARO/libadsprpc/aarch64/AOSP_rb5

# AOSP FastRPC
cd ${MODIFIED_SRC_PATH}/AOSP/fastrpc

sed -i 's/-lm/-lm -llog/' ${MODIFIED_SRC_PATH}/AOSP/fastrpc/Makefile
sed -i 's/-lpthread //' ${MODIFIED_SRC_PATH}/AOSP/fastrpc/Makefile

#./configure --host=$TARGET CC=$TOOLCHAIN/bin/$TARGET$API-clang

make CC=$TOOLCHAIN/bin/$TARGET$API-clang CFLAGS+="-I${CUTILS_INCLUDE_PATH} -I${MODIFIED_SRC_PATH}/AOSP/fastrpc/inc -DANDROID" -j$(nproc --all) all

cp --verbose -r ${MODIFIED_SRC_PATH}/AOSP/fastrpc/*.so ${BUILD_RESULTS_PATH}/AOSP/fastrpc/aarch64/AOSP_rb5
cp --verbose -r ${MODIFIED_SRC_PATH}/AOSP/fastrpc/cdsprpcd ${BUILD_RESULTS_PATH}/AOSP/fastrpc/aarch64/AOSP_rb5

##################################
cd ${MODIFIED_SRC_PATH}
rm -rf ${MODIFIED_SRC_PATH}/LINARO/*
rm -rf ${MODIFIED_SRC_PATH}/AOSP/*
cp --verbose -r ${DOWNLOAD_SRC_PATH}/LINARO/fastrpc ${MODIFIED_SRC_PATH}/LINARO
cp --verbose -r ${DOWNLOAD_SRC_PATH}/LINARO/libadsprpc ${MODIFIED_SRC_PATH}/LINARO
cp --verbose -r ${DOWNLOAD_SRC_PATH}/AOSP/fastrpc ${MODIFIED_SRC_PATH}/AOSP/fastrpc
##################################

export TARGET=armv7a-linux-androideabi # 32Bit

# Linaro FastRPC
cd ${MODIFIED_SRC_PATH}/LINARO/fastrpc
./autogen.sh

sed -i 's/-I\$(top_srcdir)\/inc/-I\$(top_srcdir)\/inc -I\$(top_srcdir)\/..\/..\/core\/libcutils\/include/' ${MODIFIED_SRC_PATH}/LINARO/fastrpc/src/Makefile.am
sed -i 's/adsprpcd_LDADD = -ldl/adsprpcd_LDADD = -ldl -llog/' ${MODIFIED_SRC_PATH}/LINARO/fastrpc/src/Makefile.am
sed -i 's/cdsprpcd_LDADD =  -ldl/cdsprpcd_LDADD = -ldl -llog/' ${MODIFIED_SRC_PATH}/LINARO/fastrpc/src/Makefile.am
sed -i 's/sdsprpcd_LDADD =  -ldl/sdsprpcd_LDADD = -ldl -llog/' ${MODIFIED_SRC_PATH}/LINARO/fastrpc/src/Makefile.am
sed -i 's/-lpthread //' ${MODIFIED_SRC_PATH}/LINARO/fastrpc/src/Makefile.am

./configure --host=$TARGET CC=$TOOLCHAIN/bin/$TARGET$API-clang

make -j$(nproc --all)

cp --verbose -r ${MODIFIED_SRC_PATH}/LINARO/fastrpc/src/.deps ${BUILD_RESULTS_PATH}/LINARO/fastrpc/armv7a/deps
cp --verbose -r ${MODIFIED_SRC_PATH}/LINARO/fastrpc/src/.libs ${BUILD_RESULTS_PATH}/LINARO/fastrpc/armv7a/libs
cp --verbose -r ${BUILD_RESULTS_PATH}/LINARO/fastrpc/armv7a/libs/*.so ${BUILD_RESULTS_PATH}/LINARO/fastrpc/armv7a/AOSP_rb5

# Linaro adsprpc
cd ${MODIFIED_SRC_PATH}/LINARO/libadsprpc
./autogen.sh

sed -i 's/-lpthread //' ${MODIFIED_SRC_PATH}/LINARO/libadsprpc/src/utils/Makefile.am
sed -i 's/-lpthread //' ${MODIFIED_SRC_PATH}/LINARO/libadsprpc/src/lib/Makefile.am

./configure --host=$TARGET CC=$TOOLCHAIN/bin/$TARGET$API-clang

make -j$(nproc --all)

cp --verbose -r ${MODIFIED_SRC_PATH}/LINARO/libadsprpc/src/lib/.libs ${BUILD_RESULTS_PATH}/LINARO/libadsprpc/armv7a/libs
cp --verbose -r ${MODIFIED_SRC_PATH}/LINARO/libadsprpc/src/utils/.libs ${BUILD_RESULTS_PATH}/LINARO/libadsprpc/armv7a/utils
cp --verbose -r ${BUILD_RESULTS_PATH}/LINARO/libadsprpc/armv7a/libs/*.so ${BUILD_RESULTS_PATH}/LINARO/libadsprpc/armv7a/AOSP_rb5
cp --verbose -r ${BUILD_RESULTS_PATH}/LINARO/libadsprpc/armv7a/utils/* ${BUILD_RESULTS_PATH}/LINARO/libadsprpc/armv7a/AOSP_rb5

# AOSP FastRPC
cd ${MODIFIED_SRC_PATH}/AOSP/fastrpc

sed -i 's/-lm/-lm -llog/' ${MODIFIED_SRC_PATH}/AOSP/fastrpc/Makefile
sed -i 's/-lpthread //' ${MODIFIED_SRC_PATH}/AOSP/fastrpc/Makefile

#./configure --host=$TARGET CC=$TOOLCHAIN/bin/$TARGET$API-clang

make CC=$TOOLCHAIN/bin/$TARGET$API-clang CFLAGS+="-I${CUTILS_INCLUDE_PATH} -I${MODIFIED_SRC_PATH}/AOSP/fastrpc/inc -DANDROID" -j$(nproc --all) all

cp --verbose -r ${MODIFIED_SRC_PATH}/AOSP/fastrpc/*.so ${BUILD_RESULTS_PATH}/AOSP/fastrpc/armv7a/AOSP_rb5
cp --verbose -r ${MODIFIED_SRC_PATH}/AOSP/fastrpc/cdsprpcd ${BUILD_RESULTS_PATH}/AOSP/fastrpc/armv7a/AOSP_rb5

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

# Failed
#adb shell mkdir /vendor/dsp
#adb push ${BUILD_RESULTS_PATH}/AOSP/fastrpc/aarch64/AOSP_rb5/* /system/vendor/lib64
#adb push ${BUILD_RESULTS_PATH}/AOSP/fastrpc/aarch64/AOSP_rb5/* /vendor/lib64
#adb push ${BUILD_RESULTS_PATH}/AOSP/fastrpc/armv7a/AOSP_rb5/* /system/vendor/lib
#adb push ${BUILD_RESULTS_PATH}/AOSP/fastrpc/armv7a/AOSP_rb5/* /vendor/lib

adb shell mkdir /vendor/dsp
adb push ${BUILD_RESULTS_PATH}/LINARO/fastrpc/aarch64/AOSP_rb5/* /system/vendor/lib64
adb push ${BUILD_RESULTS_PATH}/LINARO/fastrpc/aarch64/AOSP_rb5/* /vendor/lib64
adb push ${BUILD_RESULTS_PATH}/LINARO/fastrpc/armv7a/AOSP_rb5/* /system/vendor/lib
adb push ${BUILD_RESULTS_PATH}/LINARO/fastrpc/armv7a/AOSP_rb5/* /vendor/lib
adb push ${BUILD_RESULTS_PATH}/LINARO/fastrpc/aarch64/AOSP_rb5/* /vendor/dsp

# Failed
# adb shell mkdir /vendor/dsp
# adb push ${BUILD_RESULTS_PATH}/LINARO/libadsprpc/aarch64/AOSP_rb5/* /system/vendor/lib64
# adb push ${BUILD_RESULTS_PATH}/LINARO/libadsprpc/aarch64/AOSP_rb5/* /vendor/lib64
# adb push ${BUILD_RESULTS_PATH}/LINARO/libadsprpc/armv7a/AOSP_rb5/* /system/vendor/lib
# adb push ${BUILD_RESULTS_PATH}/LINARO/libadsprpc/armv7a/AOSP_rb5/* /vendor/lib

