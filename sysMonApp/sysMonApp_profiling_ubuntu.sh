#!/bin/bash

# SM8250 Hexagon Tensor Accelerator Overview: https://docs.qualcomm.com/bundle/80-PK882-35/resource/80-PK882-35.pdf
# Snapdragon Neural Processing Engine Quick Start Guide: https://docs.qualcomm.com/bundle/80-PF777-141/resource/80-PF777-141.pdf#page=38
# How to capture and parse sensor`s sysMonapp log correctly: https://docs.qualcomm.com/bundle/KBA-220422011853/resource/KBA-220422011853.pdf

echo "(**) Starting sysMonApp profiling Demo"

echo '(**) List adb devices:'
adb devices
export ANDROID_SERIAL="10.136.8.1:5555"
echo "(**) Using device: ${ANDROID_SERIAL}"

# Where Hexgon Dir in host and where to install sysMonApp
export HEXAGON_PATH="${HOME}/Qualcomm/Hexagon_SDK/4.5.0.3"
# export sysMonApp_host_PATH="${HEXAGON_PATH}/tools/utils/sysmon/sysMonApp"
export sysMonApp_host_PATH="${HEXAGON_PATH}/tools/utils/sysmon/sysMonAppLE_64Bit"
export sysMonApp_bin_parser="${HEXAGON_PATH}/tools/utils/sysmon/parser_linux_v2/HTML_Parser/sysmon_parser"
export Device_sysMonApp_PATH='/data/sysMonApp'
export minidm_bin="${HEXAGON_PATH}/tools/debug/mini-dm/Ubuntu18/mini-dm"

# Where DLC model in host and where to store on device

# Quant
# export HOST_DLC_PATH="${HOME}/snpe-example/test_files/dlc/inception_v3_aip50_quantized.dlc"
# export DEVICE_DLC_PATH="/data/local/tmp/inception_v3_aip50_quantized.dlc"

export HOST_DLC_PATH="${HOME}/snpe-example/test_files/dlc/inception_v3_gpu.dlc"
export DEVICE_DLC_PATH="/data/local/tmp/inception_v3_gpu.dlc"

export HOST_INPUT_RAW_PATH="${HOME}/snpe-example/test_files/data/sample_299x299/cropped/chairs.raw"
export DEVICE_INPUT_RAW_PATH="/data/local/tmp/chairs.raw"

# Where SNPE Dir in host
export SNPE_DIR="${HOME}/Qualcomm/snpe-1.66.0.3729"
export SNPE_LOG_DIR='/data/local/tmp/platformValidator/output'

# Where profiling results store on device and pull to host
export sysMonApp_saved_path='/data/local/tmp'
export sysMonApp_pull_to_path="${HOME}/Downloads"

# Define binary architeture, OS and hexagon architeture
export TARGET_ARCH='aarch64'
export TARGET_OS='ubuntu'
export TARGET_COMPILER='gcc7.5'

# Define where to install
export TARGET_SNPE_DIR="/data/${SNPE_DIR##*/}"

# Define Target BIN
export TARGET_SNPE_BIN="${TARGET_SNPE_DIR}/bin/${TARGET_ARCH}-${TARGET_OS}-${TARGET_COMPILER}"

# Set on-device envs
export TARGET_SNPE_ROOT='/home/delta/Qualcomm/snpe-1.66.0.3729' #snpe-1.66.0.3729 #1.43.0.230 #1.65.0.3676
export TARGET_ADSP_LIBS="${TARGET_SNPE_ROOT}/lib/dsp;${TARGET_SNPE_ROOT}/lib/${TARGET_ARCH}-${TARGET_OS}-${TARGET_COMPILER};/system/lib/rfsa/adsp;/system/vendor/lib/rfsa/adsp;/dsp"
export TARGET_LD_LIBS="${LD_LIBRARY_PATH}:${TARGET_SNPE_ROOT}/lib/dsp:${TARGET_SNPE_ROOT}/lib/x86_64-linux-clang:/system/lib/rfsa/adsp:/system/vendor/lib/rfsa/adsp:/dsp"

export TARGET_SNPE_LIBS="${TARGET_SNPE_DIR}/lib/${TARGET_ARCH}-${TARGET_OS}-${TARGET_COMPILER}"
export TARGET_SNPE_DSP_LIBS="${TARGET_SNPE_DIR}/lib/dsp"
export SNPE_ADSP_LIBRARY_PATH="${TARGET_SNPE_LIBS};${TARGET_SNPE_DSP_LIBS};${TARGET_ADSP_LIBS}"
export SNPE_LD_LIBRARY_PATH="${TARGET_SNPE_LIBS}:${TARGET_SNPE_DSP_LIBS}:${TARGET_LD_LIBS}"

function check_var_path_exists(){
    echo "(**) Check directory or file exists"
    if [ -d "$HEXAGON_PATH" ] 
    then
        echo "(**) \$HEXAGON_PATH $HEXAGON_PATH directory exists." 
    else
        echo "(EE) Error: \$HEXAGON_PATH $HEXAGON_PATH directory does not exists."
        exit 1
    fi

    if [ -f "$sysMonApp_host_PATH" ] 
    then
        echo "(**) \$sysMonApp_host_PATH $sysMonApp_host_PATH file exists." 
    else
        echo "(EE) Error: \$sysMonApp_host_PATH $sysMonApp_host_PATH file does not exists."
        exit 1
    fi

    if [ -f "$HOST_DLC_PATH" ] 
    then
        echo "(**) \$HOST_DLC_PATH $HOST_DLC_PATH file exists." 
    else
        echo "(EE) Error: \$HOST_DLC_PATH $HOST_DLC_PATH file does not exists."
        exit 1
    fi

    if [ -f "$HOST_INPUT_RAW_PATH" ] 
    then
        echo "(**) \$HOST_INPUT_RAW_PATH $HOST_DLC_PATH file exists." 
    else
        echo "(EE) Error: \$HOST_INPUT_RAW_PATH $HOST_INPUT_RAW_PATH file does not exists."
        exit 1
    fi

    if [ -d "$SNPE_DIR" ] 
    then
        echo "(**) \$SNPE_DIR $SNPE_DIR directory exists." 
    else
        echo "(EE) Error: \$SNPE_DIR $SNPE_DIR directory does not exists."
        exit 1
    fi

    if [ -d "$sysMonApp_pull_to_path" ] 
    then
        echo "(**) \$sysMonApp_pull_to_path $sysMonApp_pull_to_path directory exists." 
    else
        echo "(EE) Error: \$sysMonApp_pull_to_path $sysMonApp_pull_to_path directory does not exists."
        exit 1
    fi
    sleep 1
}

function adb_check_device(){
    echo "(**) Check adb devices"
    adb devices
    if [ -z "$ANDROID_SERIAL" ]
    then
      echo "\$ANDROID_SERIAL is empty"
    else
      echo "\$ANDROID_SERIAL is NOT $ANDROID_SERIAL"
    fi
}

function install(){
    # Install sysMonApp to device and give permission
    echo "(**) Install sysMonApp to device and give permission..."
    adb -s $ANDROID_SERIAL wait-for-device root
    echo "(II) Push sysMonApp from host path ${sysMonApp_host_PATH} to device ${ANDROID_SERIAL} path: ${Device_sysMonApp_PATH}"
    adb -s $ANDROID_SERIAL wait-for-device push "${sysMonApp_host_PATH}" "${Device_sysMonApp_PATH}"
    adb -s $ANDROID_SERIAL shell chmod 777 ${Device_sysMonApp_PATH}
    # Install DLC model to device
    echo "(II) Push DLC from host path ${HOST_DLC_PATH} to device ${ANDROID_SERIAL} path: ${DEVICE_DLC_PATH}"
    adb -s $ANDROID_SERIAL push $HOST_DLC_PATH $DEVICE_DLC_PATH
    echo "(II) Push test RAW image from host path ${HOST_INPUT_RAW_PATH} to device ${ANDROID_SERIAL} path: ${DEVICE_INPUT_RAW_PATH}"
    adb -s $ANDROID_SERIAL push $HOST_INPUT_RAW_PATH $DEVICE_INPUT_RAW_PATH
    adb -s $ANDROID_SERIAL shell rm -rf /sdcard/sysmo*.bin
}

function cleanup(){
    echo "(II) Uninstall previos sysMonApp"
    adb -s $ANDROID_SERIAL shell "rm -rf ${Device_sysMonApp_PATH}"
    echo "(II) Clear previos SNPE platform validator log dirs"
    adb -s $ANDROID_SERIAL shell rm -rf ${SNPE_LOG_DIR}
    rm -rf $sysMonApp_pull_to_path/SNPE_PLATFORM_VALIDDATOR*
    echo "(II) Clear previous sysMonApp proliling"
    adb -s $ANDROID_SERIAL shell rm -rf /sdcard/sysmo*.bin
    # rm -rf $sysMonApp_pull_to_path/sysMonApp_profiler_*
}

function enable_hta_firmware_logs() {
    adb -s $ANDROID_SERIAL wait-for-device root
    adb -s $ANDROID_SERIAL shell echo -n 'module msm_npu +p' > /d/dynamic_debug/control
}

function check_hta_kernel_driver() {
    adb -s $ANDROID_SERIAL shell 'dmesg | grep npu'
}

function run_minidm() {
    sudo $minidm_bin
}

function snpe_test_platform() {
    extra_args='--coreVersion --libVersion --testRuntime --debug'

    adb -s $ANDROID_SERIAL shell \
        "export ADSP_LIBRARY_PATH=\"${SNPE_ADSP_LIBRARY_PATH}\" && LD_LIBRARY_PATH=\"${SNPE_LD_LIBRARY_PATH}\" \\
        ${TARGET_SNPE_BIN}/snpe-platform-validator --help"

    echo "(**) [1/3] Validating GPU..."
    adb -s $ANDROID_SERIAL shell \
        "export ADSP_LIBRARY_PATH=\"${SNPE_ADSP_LIBRARY_PATH}\" && LD_LIBRARY_PATH=\"${SNPE_LD_LIBRARY_PATH}\" \\
        ${TARGET_SNPE_BIN}/snpe-platform-validator --runtime gpu $extra_args"
    adb pull ${SNPE_LOG_DIR} $sysMonApp_pull_to_path/SNPE_PLATFORM_VALIDDATOR_GPU
    echo "(**) [2/3] Validating DSP..."
    adb -s $ANDROID_SERIAL shell \
        "export ADSP_LIBRARY_PATH=\"${SNPE_ADSP_LIBRARY_PATH}\" && LD_LIBRARY_PATH=\"${SNPE_LD_LIBRARY_PATH}\" \\
        ${TARGET_SNPE_BIN}/snpe-platform-validator --runtime dsp $extra_args"
    adb pull ${SNPE_LOG_DIR} $sysMonApp_pull_to_path/SNPE_PLATFORM_VALIDDATOR_DSP
    echo "(**) [3/3] Validating AIP (HTA+HVX) runtime..."
    adb -s $ANDROID_SERIAL shell \
        "export ADSP_LIBRARY_PATH=\"${SNPE_ADSP_LIBRARY_PATH}\" && LD_LIBRARY_PATH=\"${SNPE_LD_LIBRARY_PATH}\" \\
        ${TARGET_SNPE_BIN}/snpe-platform-validator --runtime aip $extra_args"
    adb pull ${SNPE_LOG_DIR} $sysMonApp_pull_to_path/SNPE_PLATFORM_VALIDDATOR_AIP
}

function run_snpe_throughput_gpu() {
    # Start an SNPE inference to profiling
    perf_profile='burst'
    duration='30'
    extra_snpe_throughput_args='--verbose'
    run_order='gpu,cpu'

    echo "(**) Run thoughput:"
    echo "(**) Model: ${DEVICE_DLC_PATH}"
    echo "(**) Input: ${DEVICE_INPUT_RAW_PATH}"
    echo "(**) Perf : ${perf_profile}"
    echo "(**) Duration: ${duration}"
    echo "(**) Extra args: ${extra_snpe_throughput_args}"
    echo "(**) Run order: ${run_order}"

    sleep 1
    echo "(!!) Start GPU throughput"
    adb -s $ANDROID_SERIAL shell \
        "export ADSP_LIBRARY_PATH=\"${SNPE_ADSP_LIBRARY_PATH}\" && LD_LIBRARY_PATH=\"${SNPE_LD_LIBRARY_PATH}\" \\
        ${TARGET_SNPE_BIN}/snpe-throughput-net-run --container ${DEVICE_DLC_PATH} --input_raw ${DEVICE_INPUT_RAW_PATH} --duration $duration --perf_profile $perf_profile --runtime_order $run_order $extra_snpe_throughput_args"
}

function run_snpe_throughput_cdsp() {
    # Start an SNPE inference to profiling
    perf_profile='burst'
    duration='5'
    extra_snpe_throughput_args='--verbose'
    run_order='dsp,cpu'
    
    echo "(**) Run thoughput:"
    echo "(**) Model: ${DEVICE_DLC_PATH}"
    echo "(**) Input: ${DEVICE_INPUT_RAW_PATH}"
    echo "(**) Perf : ${perf_profile}"
    echo "(**) Duration: ${duration}"
    echo "(**) Extra args: ${extra_snpe_throughput_args}"
    echo "(**) Run order: ${run_order}"

    sleep 1
    echo "(!!) Start DSP throughput"
    adb -s $ANDROID_SERIAL shell \
        "export ADSP_LIBRARY_PATH=\"${SNPE_ADSP_LIBRARY_PATH}\" && LD_LIBRARY_PATH=\"${SNPE_LD_LIBRARY_PATH}\" \\
        ${TARGET_SNPE_BIN}/snpe-throughput-net-run --container ${DEVICE_DLC_PATH} --input_raw ${DEVICE_INPUT_RAW_PATH} --duration $duration --perf_profile $perf_profile --runtime_order $run_order $extra_snpe_throughput_args"
}

function run_snpe_throughput_aip() {
    # Start an SNPE inference to profiling
    perf_profile='burst'
    duration='5'
    extra_snpe_throughput_args='--verbose'
    run_order='aip,dsp,cpu'

    echo "(**) Run thoughput:"
    echo "(**) Model: ${DEVICE_DLC_PATH}"
    echo "(**) Input: ${DEVICE_INPUT_RAW_PATH}"
    echo "(**) Perf : ${perf_profile}"
    echo "(**) Duration: ${duration}"
    echo "(**) Extra args: ${extra_snpe_throughput_args}"
    echo "(**) Run order: ${run_order}"

    sleep 1
    echo "(!!) Start AIP throughput"
    adb -s $ANDROID_SERIAL shell \
        "export ADSP_LIBRARY_PATH=\"${SNPE_ADSP_LIBRARY_PATH}\" && LD_LIBRARY_PATH=\"${SNPE_LD_LIBRARY_PATH}\" \\
        ${TARGET_SNPE_BIN}/snpe-throughput-net-run --container ${DEVICE_DLC_PATH} --input_raw ${DEVICE_INPUT_RAW_PATH} --duration $duration --perf_profile $perf_profile --runtime_order $run_order $extra_snpe_throughput_args"
}

function sysMonApp_help() {
    # sysMonApp Profiling help
    adb shell "export ADSP_LIBRARY_PATH=\"${TARGET_ADSP_LIBS}\" && LD_LIBRARY_PATH=\"${TARGET_LD_LIBS}\" \\
        /data/sysMonApp --help"
    sleep 10
}

function sysMonApp_cdsp_profiling() {

    export extra_profile_cdsp_args="--defaultSetEnable --debugLevel 1 --profileFastrpcTimeline --profileLPMLA --samplingPeriod 1 --duration 15 --dcvsOption"

    # sysMonApp Profiling
    echo "(!!) Start CDSP profiler"
    adb shell "export ADSP_LIBRARY_PATH=\"${TARGET_ADSP_LIBS}\" && LD_LIBRARY_PATH=\"${TARGET_LD_LIBS}\" \\
        /data/sysMonApp profiler --profile 1 --q6 cdsp $extra_profile_cdsp_args"
    sleep 3
    mkdir $sysMonApp_pull_to_path/sysMonApp_profiler_cdsp

    adb pull /sdcard/sysmon_cdsp.bin $sysMonApp_pull_to_path/sysMonApp_profiler_cdsp
    adb pull /data/sysmon_cdsp.bin $sysMonApp_pull_to_path/sysMonApp_profiler_cdsp
    
    # $sysMonApp_bin_parser $sysMonApp_pull_to_path/sysMonApp_profiler_cdsp/sysmon_cdsp.bin --tlp $sysMonApp_pull_to_path/sysMonApp_profiler_cdsp/sysmon_tlp.bin --outdir $sysMonApp_pull_to_path/sysMonApp_profiler_cdsp --summary
    $sysMonApp_bin_parser $sysMonApp_pull_to_path/sysMonApp_profiler_cdsp/sysmon_cdsp.bin --outdir $sysMonApp_pull_to_path/sysMonApp_profiler_cdsp --summary

}

function sysMonApp_npu_profiling() {

    export extra_profile_npu_args="--defaultSetEnable --debugLevel 1 --profileFastrpcTimeline --profileLPMLA --samplingPeriod 1 --duration 15":

    # sysMonApp Profiling
    sleep 3
    echo "(!!) Start NPU profiler"
    adb shell "export ADSP_LIBRARY_PATH=\"${TARGET_ADSP_LIBS}\" && LD_LIBRARY_PATH=\"${TARGET_LD_LIBS}\" \\
        /data/sysMonApp profiler --q6 npu $extra_profile_npu_args"

    mkdir $sysMonApp_pull_to_path/sysMonApp_profiler_npu

    adb pull /sdcard/sysmon_npu.bin $sysMonApp_pull_to_path/sysMonApp_profiler_npu
    adb pull /data/sysmon_npu.bin $sysMonApp_pull_to_path/sysMonApp_profiler_npu
    
    $sysMonApp_bin_parser $sysMonApp_pull_to_path/sysMonApp_profiler_npu/sysmon_npu.bin --outdir $sysMonApp_pull_to_path/sysMonApp_profiler_npu --summary
    
}

function sysMonApp_cdsp_npu_profiling() {

    export extra_profile_cdsp_npu_args="--defaultSetEnable --debugLevel 1 --profileFastrpcTimeline --profileLPMLA --samplingPeriod 1 --duration 15"

    # sysMonApp Profiling
    sleep 3
    echo "(!!) Run cdsp_npu profiler"
    adb shell "export ADSP_LIBRARY_PATH=\"${TARGET_ADSP_LIBS}\" && LD_LIBRARY_PATH=\"${TARGET_LD_LIBS}\" \\
        /data/sysMonApp profiler --q6 npu --cdsp 1 $extra_profile_cdsp_npu_args"

    mkdir $sysMonApp_pull_to_path/sysMonApp_profiler_cdsp_npu

    adb pull /sdcard/sysmon_cdsp.bin $sysMonApp_pull_to_path/sysMonApp_profiler_cdsp_npu
    adb pull /sdcard/sysmon_npu.bin $sysMonApp_pull_to_path/sysMonApp_profiler_cdsp_npu
    adb pull /sdcard/sysmon_cdsp_npu.bin $sysMonApp_pull_to_path/sysMonApp_profiler_cdsp_npu

    adb pull /data/sysmon_cdsp.bin $sysMonApp_pull_to_path/sysMonApp_profiler_cdsp_npu
    adb pull /data/sysmon_npu.bin $sysMonApp_pull_to_path/sysMonApp_profiler_cdsp_npu
    adb pull /data/sysmon_cdsp_npu.bin $sysMonApp_pull_to_path/sysMonApp_profiler_cdsp_npu
    
    $sysMonApp_bin_parser $sysMonApp_pull_to_path/sysMonApp_profiler_cdsp_npu/sysmon_cdsp.bin --outdir $sysMonApp_pull_to_path/sysMonApp_profiler_cdsp_npu/cdsp --summary
    $sysMonApp_bin_parser $sysMonApp_pull_to_path/sysMonApp_profiler_cdsp_npu/sysmon_npu.bin --outdir $sysMonApp_pull_to_path/sysMonApp_profiler_cdsp_npu/npu --summary
    $sysMonApp_bin_parser $sysMonApp_pull_to_path/sysMonApp_profiler_cdsp_npu/sysmon_cdsp_npu.bin --outdir $sysMonApp_pull_to_path/sysMonApp_profiler_cdsp_npu/cdsp_npu --summary
    
}

check_var_path_exists
cleanup
install
sysMonApp_help

run_snpe_throughput_gpu &
sysMonApp_dsp_profiling

#run_snpe_throughput_aip &
#sysMonApp_cdsp_npu_profiling