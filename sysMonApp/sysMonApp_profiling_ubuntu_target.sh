#!/bin/bash

# SM8250 Hexagon Tensor Accelerator Overview: https://docs.qualcomm.com/bundle/80-PK882-35/resource/80-PK882-35.pdf
# Snapdragon Neural Processing Engine Quick Start Guide: https://docs.qualcomm.com/bundle/80-PF777-141/resource/80-PF777-141.pdf#page=38
# How to capture and parse sensor`s sysMonapp log correctly: https://docs.qualcomm.com/bundle/KBA-220422011853/resource/KBA-220422011853.pdf

echo "(**) Starting sysMonApp profiling Demo"

export Device_sysMonApp_PATH='/data/sysMonApp'

# Where DLC model in host and where to store on device
# Quant
export DEVICE_DLC_PATH="/data/local/tmp/inception_v3_aip50_quantized.dlc"
# Float
export DEVICE_DLC_PATH="/data/local/tmp/inception_v3_gpu.dlc"
export DEVICE_INPUT_RAW_PATH="/data/local/tmp/chairs.raw"

# Where profiling results store on device and pull to host
export sysMonApp_saved_path='/data/local/tmp'

# Define binary architeture, OS and hexagon architeture
export TARGET_ARCH='aarch64'
export TARGET_OS='ubuntu'
export TARGET_COMPILER='gcc7.5'

# Define where to install
export TARGET_SNPE_DIR="/data/snpe-1.66.0.3729"
export SNPE_LOG_DIR='/data/local/tmp/platformValidator/output'

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

export ADSP_LIBRARY_PATH="${ADSP_LIBRARY_PATH};${SNPE_ADSP_LIBRARY_PATH}"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${SNPE_LD_LIBRARY_PATH}"

function check_var_path_exists(){
    echo "(**) Check directory or file exists"

    if [ -f "$Device_sysMonApp_PATH" ] 
    then
        echo "(**) \$Device_sysMonApp_PATH $Device_sysMonApp_PATH file exists." 
    else
        echo "(EE) Error: \$Device_sysMonApp_PATH $Device_sysMonApp_PATH file does not exists."
        exit 1
    fi
    
    if [ -f "$DEVICE_DLC_PATH" ] 
    then
        echo "(**) \$DEVICE_DLC_PATH $DEVICE_DLC_PATH file exists." 
    else
        echo "(EE) Error: \$DEVICE_DLC_PATH $DEVICE_DLC_PATH file does not exists."
        exit 1
    fi

    if [ -f "$DEVICE_INPUT_RAW_PATH" ] 
    then
        echo "(**) \$DEVICE_INPUT_RAW_PATH $DEVICE_INPUT_RAW_PATH file exists." 
    else
        echo "(EE) Error: \$DEVICE_INPUT_RAW_PATH $DEVICE_INPUT_RAW_PATH file does not exists."
        exit 1
    fi

    if [ -d "$sysMonApp_saved_path" ] 
    then
        echo "(**) \$sysMonApp_saved_path $sysMonApp_saved_path directory exists." 
    else
        echo "(EE) Error: \$sysMonApp_saved_path $sysMonApp_saved_path directory does not exists."
        exit 1
    fi
    sleep 1
}

function snpe_test_platform() {
    extra_args='--coreVersion --libVersion --testRuntime --debug'
    rm -rf '/data/snpe_test_platform'
    mkdir '/data/snpe_test_platform'

    ${TARGET_SNPE_BIN}/snpe-platform-validator --help

    echo "(**) [1/3] Validating GPU..."
    ${TARGET_SNPE_BIN}/snpe-platform-validator --runtime gpu $extra_args
    mv ${SNPE_LOG_DIR} '/data/snpe_test_platform/snpe_test_platform_gpu'
    
    echo "(**) [2/3] Validating DSP..."
    ${TARGET_SNPE_BIN}/snpe-platform-validator --runtime dsp $extra_args
    mv ${SNPE_LOG_DIR} '/data/snpe_test_platform/snpe_test_platform_dsp'

    echo "(**) [3/3] Validating AIP (HTA+HVX) runtime..."
    ${TARGET_SNPE_BIN}/snpe-platform-validator --runtime aip $extra_args
    mv ${SNPE_LOG_DIR} '/data/snpe_test_platform/snpe_test_platform_aip'
}

function run_snpe_throughput_gpu() {
    # Start an SNPE inference to profiling
    perf_profile='burst'
    duration='30'
    extra_snpe_throughput_args='--verbose --priority_hint high --enable_init_cache'
    run_order='gpu,cpu'

    echo "(**) Run thoughput:"
    echo "(**) Model: ${DEVICE_DLC_PATH}"
    echo "(**) Input: ${DEVICE_INPUT_RAW_PATH}"
    echo "(**) Perf : ${perf_profile}"
    echo "(**) Duration: ${duration}"
    echo "(**) Extra args: ${extra_snpe_throughput_args}"
    echo "(**) Run order: ${run_order}"

    sleep 5
    echo "(!!) Start GPU throughput"
    ${TARGET_SNPE_BIN}/snpe-throughput-net-run --container ${DEVICE_DLC_PATH} --input_raw ${DEVICE_INPUT_RAW_PATH} --duration $duration --perf_profile $perf_profile --runtime_order $run_order $extra_snpe_throughput_args
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

    sleep 5
    echo "(!!) Start DSP throughput"
    ${TARGET_SNPE_BIN}/snpe-throughput-net-run --container ${DEVICE_DLC_PATH} --input_raw ${DEVICE_INPUT_RAW_PATH} --duration $duration --perf_profile $perf_profile --runtime_order $run_order $extra_snpe_throughput_args
}

function run_snpe_throughput_aip() {
    # Start an SNPE inference to profiling
    perf_profile='burst'
    duration='5'
    extra_snpe_throughput_args='--verbose --priority_hint high --enable_init_cache'
    run_order='aip,dsp,cpu'

    echo "(**) Run thoughput:"
    echo "(**) Model: ${DEVICE_DLC_PATH}"
    echo "(**) Input: ${DEVICE_INPUT_RAW_PATH}"
    echo "(**) Perf : ${perf_profile}"
    echo "(**) Duration: ${duration}"
    echo "(**) Extra args: ${extra_snpe_throughput_args}"
    echo "(**) Run order: ${run_order}"

    sleep 5
    echo "(!!) Start AIP throughput"
    ${TARGET_SNPE_BIN}/snpe-throughput-net-run --container ${DEVICE_DLC_PATH} --input_raw ${DEVICE_INPUT_RAW_PATH} --duration $duration --perf_profile $perf_profile --runtime_order $run_order $extra_snpe_throughput_args
}

function sysMonApp_help() {
    # sysMonApp Profiling help
    $Device_sysMonApp_PATH --help
    sleep 10
}

function sysMonApp_cdsp_profiling() {

    export extra_profile_cdsp_args="--defaultSetEnable --debugLevel 1 --profileFastrpcTimeline --profileLPMLA --samplingPeriod 1 --duration 15"

    # sysMonApp Profiling
    echo "(!!) Start CDSP profiler"
    $Device_sysMonApp_PATH profiler --profile 1 --q6 cdsp $extra_profile_cdsp_args
    sleep 3
    rm -rf /data/sysmon_cdsp_profile
    mkdir /data/sysmon_cdsp_profile

    mv /sdcard/sysmon_cdsp.bin /data/sysmon_cdsp_profile
    mv /data/sysmon_cdsp.bin /data/sysmon_cdsp_profile

}

function sysMonApp_npu_profiling() {

    export extra_profile_npu_args="":

    # sysMonApp Profiling
    echo "(!!) Start NPU profiler"
    $Device_sysMonApp_PATH profiler --q6 npu

    sleep 1
    rm -rf /data/sysmon_npu_profile
    mkdir /data/sysmon_npu_profile

    mv /sdcard/sysmon_npu.bin /data/sysmon_npu_profile
    mv /data/sysmon_npu.bin /data/sysmon_npu_profile
    
}

function sysMonApp_cdsp_npu_profiling() {

    export extra_profile_cdsp_npu_args="--defaultSetEnable --debugLevel 1 --profileFastrpcTimeline --profileLPMLA --samplingPeriod 1 --duration 15"

    # sysMonApp Profiling
    sleep 3
    echo "(!!) Run cdsp_npu profiler"
    $Device_sysMonApp_PATH --q6 npu --cdsp 1 $extra_profile_cdsp_npu_args

    rm -rf /data/sysmon_cdsp_npu_profile
    mkdir /data/sysmon_cdsp_npu_profile

    mv /sdcard/sysmon_cdsp.bin /data/sysmon_cdsp_npu_profile
    mv /sdcard/sysmon_npu.bin /data/sysmon_cdsp_npu_profile
    mv /sdcard/sysmon_cdsp_npu.bin /data/sysmon_cdsp_npu_profile

    mv /data/sysmon_cdsp.bin /data/sysmon_cdsp_npu_profile
    mv /data/sysmon_npu.bin /data/sysmon_cdsp_npu_profile
    mv /data/sysmon_cdsp_npu.bin /data/sysmon_cdsp_npu_profile
    
}

#snpe_test_platform
#sysMonApp_help

run_snpe_throughput_gpu &
sysMonApp_cdsp_profiling

#run_snpe_throughput_aip &
#sysMonApp_cdsp_npu_profiling