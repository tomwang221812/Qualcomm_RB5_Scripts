#!/bin/bash

set -euxo pipefail

echo "Enter the sudo password: "
read PW

echo "(II) User Home Dir: $HOME"
echo "(II) Crrent Dir: $PWD"
echo "(II) python3 path: $(which python3)"
export AOSP_TOPDIR=${PWD}

echo "(II) Download and install git-repo from Google"
echo $PW | sudo mkdir -p ${HOME}/.bin
curl https://storage.googleapis.com/git-repo-downloads/repo > ${HOME}/.bin/repo
echo $PW | sudo chmod a+rx ${HOME}/.bin/repo

echo "(II) Get sources (gits) using git-repo"
python3 ${HOME}/.bin/repo init -u https://android.googlesource.com/platform/manifest -b master
${HOME}/.bin/repo sync -j$(nproc --all)

echo "(II) Download and Extract vendor images/packages"
${PWD}/device/linaro/dragonboard/fetch-vendor-package.sh

echo "(II) Setup AOSP conpile env"
source ${PWD}/build/envsetup.sh

echo "(II) Setup Board Information to tell the compiler how to build images for RB5"
echo "(II) RB5-{eng | user | userdebug}"
lunch rb5-userdebug

echo "(II) Start to build... (May take a long time)"
make -j$(nproc --all)