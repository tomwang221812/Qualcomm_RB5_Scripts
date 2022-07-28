#!/bin/bash

set -euxo pipefail

echo "Make sure you are under the directory"
echo "you build the AOSP images before!!"
echo "You currently in ${PWD}, is this correct?"
read COND
export AOSP_TOPDIR=${PWD}

echo "Enter the sudo password: "
read PW

echo "(II) User Home Dir: $HOME"
echo "(II) Crrent Dir: $PWD"
echo "(II) python3 path: $(which python3)"

echo "(II) Download and install git-repo from Google"
curl https://storage.googleapis.com/git-repo-downloads/repo > ${HOME}/.bin/repo
echo $PW | sudo chmod a+rx ${HOME}/.bin/repo

echo "(II) Make a new dir for kernel build"
mkdir ${AOSP_TOPDIR}/repo-rb5-kernel
echo "(II) Enter dir ${AOSP_TOPDIR}/repo-rb5-kernel"
cd ${AOSP_TOPDIR}/repo-rb5-kernel

echo "(II) Get sources (gits) using git-repo"
python3 ${HOME}/.bin/repo init -u https://android.googlesource.com/kernel/manifest -b common-android-mainline
${HOME}/.bin/repo sync -j$(nproc --all) -c

echo "(II) Clear output path"
echo $PW | sudo rm -rf out/*

echo "(II) Start to build RB5 kernel"
BUILD_CONFIG=common/build.config.db845c ./build/build.sh

echo "(II) Finished! Go back to AOSP image dir ${AOSP_TOPDIR} and delete all objects in ${AOSP_TOPDIR}/device/linaro/dragonboard-kernel/android-mainline"
cd ${AOSP_TOPDIR}
echo $PW | sudo rm -rf ${AOSP_TOPDIR}/device/linaro/dragonboard-kernel/android-mainline

echo "(II) Copy built kernel"
echo $PW | cp -R ${AOSP_TOPDIR}/repo-rb5-kernel/out/android-mainline/dist ${AOSP_TOPDIR}/device/linaro/dragonboard-kernel/android-mainline

echo "(II) RB5-{eng | user | userdebug}"
lunch rb5-userdebug

echo "(II) Start to rebuild... (May take a long time)"
make TARGET_KERNEL_USE=mainline -j$(nproc --all)