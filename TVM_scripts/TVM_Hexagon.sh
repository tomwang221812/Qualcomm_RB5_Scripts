#!/bin/bash

echo "Enter the sudo password: "
read PW

echo "(II) User Home Dir: $HOME"

export TVM_HOME="$HOME/tvm"
export PYTHONPATH=$TVM_HOME/python:${PYTHONPATH}

echo "(**) TVM_HOME   = $TVM_HOME"
echo "(**) PYTHONPATH = $PYTHONPATH"

cd $TVM_HOME

# Set clang version and CPP compiler
# You must use LLVM version >14 to support hexagon HVX FLOAT!!
export LLVM_VERSION='14'
export LLVM_CONFIG="llvm-config-${LLVM_VERSION}"
export LLVM_C_COMPILER="clang-${LLVM_VERSION}"
export LLVM_CPP_COMPILER="clang++-${LLVM_VERSION}"

echo "(**) LLVM version           = $LLVM_VERSION"
echo "(**) LLVM config            = $LLVM_CONFIG"
echo "(**) LLVM C Compiler Path   = $LLVM_C_COMPILER"
echo "(**) LLVM CXX Compiler Path = $LLVM_CPP_COMPILER"

# Setup Qualcomm Hexagon Environment
export HEXAGON_SDK_VERSION='4.5.0.3' #'5.0.0.0'
export HEXAGON_TOOLCHAIN_VERSION='8.5.08' #'8.5.10'
export HEXAGON_SDK="$HOME/Qualcomm/Hexagon_SDK/$HEXAGON_SDK_VERSION"
export HEXAGON_SDK_ROOT=$HEXAGON_SDK
export HEXAGON_TOOLCHAIN="$HEXAGON_SDK/tools/HEXAGON_Tools/$HEXAGON_TOOLCHAIN_VERSION/Tools"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/$LLVM_CONFIG

# Setup target hexagon variables (This only affect rpc and runtime for Android and Hexagon and x86 and simulator)
export DSP_ARCH="v66"

echo "(**) HEXAGON SDK PATH       = $HEXAGON_SDK_ROOT"
echo "(**) HEXAGON TOOLCHAIN PATH = $HEXAGON_TOOLCHAIN"
echo "(**) LD_LIBRARY_PATH        = $LD_LIBRARY_PATH"

echo "(**) Setup Hexagon Environment: $HEXAGON_SDK/setup_sdk_env.source"
source "$HEXAGON_SDK/setup_sdk_env.source"

echo "(**) Build Fastrpc QAIC (IDL Compiler)"
echo $PW | sudo make -C $HEXAGON_SDK_ROOT/ipc/fastrpc/qaic/ clean
echo $PW | sudo make -C $HEXAGON_SDK_ROOT/ipc/fastrpc/qaic/

# Setup Android NDK Environment
export ANDROID_NDK_VERSION='25.0.8775105'
export ANDROID_NDK="$HOME/Android/Sdk/ndk/$ANDROID_NDK_VERSION/build/cmake/android.toolchain.cmake"

echo "(**) ANDROID NDK PATH = $ANDROID_NDK"

# Setup Build Directories
export build_output_dir="$HOME/tvm/build"
export TVM_LIBRARY_PATH="$build_output_dir"
export build_output_hexagon_api="$build_output_dir/hexagon_api_output"
export HEXAGON_RPC_LIB_DIR="$build_output_dir/hexagon_api_output"

# Fix MobileNet Test Issue
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python

#============Start build hexagon_api============#
echo '#============Start build hexagon_api============#'
set -x

# echo $PW | sudo rm -rf $build_output_dir
mkdir -p $build_output_dir

# Build hexagon_api
cd $TVM_HOME
cd apps/hexagon_api
# echo $PW | sudo rm -rf build
mkdir build
cd build
cmake   -DANDROID_ABI=arm64-v8a \
        -DANDROID_PLATFORM=android-28 \
        -DUSE_ANDROID_TOOLCHAIN=$ANDROID_NDK \
        -DUSE_HEXAGON_ARCH=$DSP_ARCH \
        -DUSE_HEXAGON_SDK=$HEXAGON_SDK \
        -DUSE_HEXAGON_TOOLCHAIN=$HEXAGON_TOOLCHAIN \
        -DUSE_OUTPUT_BINARY_DIR=$build_output_hexagon_api \
        -DCMAKE_C_COMPILER="${LLVM_C_COMPILER}" \
        -DCMAKE_CXX_COMPILER="${LLVM_CPP_COMPILER}" \
        -DUSE_HEXAGON_GTEST="${HEXAGON_SDK_ROOT}/utils/googletest/gtest" $TVM_HOME/apps/hexagon_api

make -j$(nproc --all)

# Finishaed hexagon_api

#============Start build Hexagon_launcher============#
echo '#============Start build Hexagon_launcher============#'
cd $TVM_HOME
cd apps/hexagon_launcher
# echo $PW | sudo rm -rf build_launcher_hexagon
mkdir build_launcher_hexagon
cd build_launcher_hexagon
cmake -DCMAKE_C_COMPILER=$HEXAGON_TOOLCHAIN/bin/hexagon-clang \
      -DCMAKE_CXX_COMPILER=$HEXAGON_TOOLCHAIN/bin/hexagon-clang++ \
      -DUSE_HEXAGON_ARCH=$DSP_ARCH \
      -DUSE_HEXAGON_SDK=$HEXAGON_SDK $TVM_HOME/apps/hexagon_launcher/cmake/hexagon

make -j$(nproc --all)

cd $TVM_HOME
cd apps/hexagon_launcher
# echo $PW | sudo rm -rf build_launcher_android
mkdir build_launcher_android
cd build_launcher_android
cmake -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK \
      -DANDROID_ABI=arm64-v8a \
      -DANDROID_PLATFORM=android-28 \
      -DUSE_HEXAGON_SDK=$HEXAGON_SDK \
      -DUSE_HEXAGON_ARCH=$DSP_ARCH $TVM_HOME/apps/hexagon_launcher/cmake/android

make -j$(nproc --all)

#============Start build TVM============#
echo '#============Start build TVM============#'
cd $TVM_HOME
# Build TVM with Hexagon
set -euxo pipefail

cd $build_output_dir
echo $PW | sudo rm -rf ./config.cmake
cp ../cmake/config.cmake .

echo set\(USE_SORT ON\) >> config.cmake
echo set\(USE_RPC ON\) >> config.cmake
echo set\(USE_MICRO ON\) >> config.cmake
echo set\(USE_MICRO_STANDALONE_RUNTIME ON\) >> config.cmake
echo set\(USE_LLVM "${LLVM_CONFIG}"\) >> config.cmake
echo set\(USE_HEXAGON "ON"\) >> config.cmake
echo set\(USE_HEXAGON_SDK "${HEXAGON_SDK_ROOT}"\) >> config.cmake
echo set\(USE_CCACHE OFF\) >> config.cmake
echo set\(SUMMARIZE ON\) >> config.cmake

cmake -DCMAKE_CXX_COMPILER="${LLVM_CPP_COMPILER}" ..

make -j$(nproc --all)
echo $PW | sudo make install

cd $TVM_HOME

# Run TVM unittest
#./tests/scripts/task_python_unittest.sh

# Run Hexagon Test
./tests/scripts/task_python_hexagon.sh --device 10.136.8.136:5555 #333e1468
# export PATH=$PATH:$build_output_dir/sim_dev-prefix/src/sim_dev-build
