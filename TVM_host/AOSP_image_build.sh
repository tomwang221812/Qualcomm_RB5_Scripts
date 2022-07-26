#!/bin/bash

set -euxo pipefail

echo "Enter the sudo password: "
read PW

echo "(II) User Home Dir: $HOME"
echo "(II) Crrent DIr: $PWD"
echo "(II) python3 path: $(which python3)"

curl https://storage.googleapis.com/git-repo-downloads/repo > ${HOME}/.bin/repo
echo $PW | sudo chmod a+rx ${HOME}/.bin/repo

python3 ${HOME}/.bin/repo init -u https://android.googlesource.com/platform/manifest -b master
${HOME}/.bin/repo sync -j$(nproc --all)
${PWD}/device/linaro/dragonboard/fetch-vendor-package.sh
source ${PWD}/build/envsetup.sh
lunch rb5-userdebug
make -j$(nproc --all)