#!/bin/bash

echo "(**) Starting sysMonApp benchmark Demo"

exho '(**) List adb devices:'
adb devices
export ANDROID_SERIAL="10.136.8.1:5555"
echo "(**) Using device: ${ANDROID_SERIAL}"

# Where Hexgon Dir in host and where to install sysMonApp
export HEXAGON_PATH="${HOME}/Qualcomm/Hexagon_SDK/4.5.0.3"
# export sysMonApp_host_PATH="${HEXAGON_PATH}/tools/utils/sysmon/sysMonApp"
export sysMonApp_host_PATH="${HEXAGON_PATH}/tools/utils/sysmon/sysMonAppLE_64Bit"
export Device_sysMonApp_PATH='/data/sysMonApp'

# Where profiling results store on device and pull to host
export sysMonApp_saved_path='/data/local/tmp'
export sysMonApp_pull_to_path="${HOME}/Downloads"

# Set on-device envs
export TARGET_SNPE_ROOT='/home/delta/Qualcomm/snpe-1.66.0.3729' #snpe-1.66.0.3729 #1.43.0.230 #1.65.0.3676
export TARGET_ADSP_LIBS="${TARGET_SNPE_ROOT}/lib/dsp;${TARGET_SNPE_ROOT}/lib/aarch64-ubuntu-gcc7.5;/system/lib/rfsa/adsp;/system/vendor/lib/rfsa/adsp;/dsp"
export TARGET_LD_LIBS="${LD_LIBRARY_PATH}:${TARGET_SNPE_ROOT}/lib/dsp:${TARGET_SNPE_ROOT}/lib/x86_64-linux-clang:/system/lib/rfsa/adsp:/system/vendor/lib/rfsa/adsp:/dsp"

# export benchmark options
export power_level='0' # 0 = Turbo, 1 = Nominal, 2 = SVS1, 3=SVS2, and 4 or higher is VDD_min
export img_w='1920'
export img_h='1080'
export latency='10' # The sleep latency tolerance threshold (in micro-seconds) in the DSP. The higher the value, the deeper level of sleep will be allowed when idle. Usually this need not be modified (1000 is default)
export rpc_loops='1' # Number of round-trip RPC invocations.
export dsp_loops='1' # Number of iterations of function within the DSP per RPC invocations.
export interval_rpc_inv='0' # each RPC invocation (micro seconds) (default 33333, i.e. 30 fps).
export hvx_units='4' # Specifies number of HVX units to be used (Default: 2) But 'integrate', 'fft', 'fft_vtcm' functions supports only 2 HVX units.
export hvx_iter='1' # hvx iterations - Number of HVX outer loop count iteration
export extra_benchmark_options="-cdv -p ${power_level} -w $img_w -h $img_h -y $latency -L $rpc_loops -l $dsp_loops -u $interval_rpc_inv -n $hvx_units -r $hvx_iter"
export benchmark_prefix='sysMonApp_benchmark_'

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

    if [ -d "$sysMonApp_pull_to_path" ] 
    then
        echo "(**) \$sysMonApp_pull_to_path $sysMonApp_pull_to_path directory exists." 
    else
        echo "(EE) Error: \$sysMonApp_pull_to_path $sysMonApp_pull_to_path directory does not exists."
        exit 1
    fi
    sleep 3
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
}

function cleanup(){
    echo "(II) Uninstall previos sysMonApp"
    adb -s $ANDROID_SERIAL shell "rm -rf ${Device_sysMonApp_PATH}"
    echo "(II) Clear previos sysMonApp benchmark log csv"
    adb -s $ANDROID_SERIAL shell "rm -rf ${sysMonApp_saved_path}/${benchmark_prefix}*.csv"
}

function benchmark_oneshot(){
    echo $1 $2 $3
    echo "(**) $1 Benchmarking $2"
    adb -s $ANDROID_SERIAL shell "export ADSP_LIBRARY_PATH=\"${TARGET_ADSP_LIBS}\" && LD_LIBRARY_PATH=\"${TARGET_LD_LIBS}\" \\
        ${Device_sysMonApp_PATH} benchmark -f $2 ${extra_benchmark_options} $3 -o ${sysMonApp_saved_path}/${benchmark_prefix}$2.csv"
    adb pull ${sysMonApp_saved_path}/${benchmark_prefix}$2.csv $sysMonApp_pull_to_path
    sleep 0.5
}

function benchmark(){

    set +e
    # sysMonApp Benchmarking
    echo "(**) [ 0/15]Print Benchmark options..."
    adb -s $ANDROID_SERIAL shell "export ADSP_LIBRARY_PATH=\"${TARGET_ADSP_LIBS}\" && LD_LIBRARY_PATH=\"${TARGET_LD_LIBS}\" \\
        ${Device_sysMonApp_PATH} benchmark --help"

    benchmark_total=17
    declare -i i=1
    benchmark_oneshot "[$i/$benchmark_total]" 'conv3x3' && i=$((i + 1))
    benchmark_oneshot "[$i/$benchmark_total]" 'dilate3x3' && i=$((i + 1))
    benchmark_oneshot "[$i/$benchmark_total]" 'dilate5x5' && i=$((i + 1))
    benchmark_oneshot "[$i/$benchmark_total]" 'gaussian7x7' && i=$((i + 1))
    benchmark_oneshot "[$i/$benchmark_total]" 'integrate' '-n 2' && i=$((i + 1))
    benchmark_oneshot "[$i/$benchmark_total]" 'epsilon' && i=$((i + 1))
    benchmark_oneshot "[$i/$benchmark_total]" 'bilateral' && i=$((i + 1))
    benchmark_oneshot "[$i/$benchmark_total]" 'bilateral_vtcm' && i=$((i + 1))
    benchmark_oneshot "[$i/$benchmark_total]" 'fast9' && i=$((i + 1))
    benchmark_oneshot "[$i/$benchmark_total]" 'sobel3x3' && i=$((i + 1))
    benchmark_oneshot "[$i/$benchmark_total]" 'histogram' && i=$((i + 1))
    benchmark_oneshot "[$i/$benchmark_total]" 'ncc8x8' && i=$((i + 1))
    benchmark_oneshot "[$i/$benchmark_total]" 'fft' '-n 2' && i=$((i + 1))
    benchmark_oneshot "[$i/$benchmark_total]" 'fft_vtcm' '-n 2' && i=$((i + 1))
    benchmark_oneshot "[$i/$benchmark_total]" 'crash10' && i=$((i + 1))
    benchmark_oneshot "[$i/$benchmark_total]" 'box11' && i=$((i + 1))
    benchmark_oneshot "[$i/$benchmark_total]" 'harriscorner' && i=$((i + 1))

    echo "(**) Finished sysMonApp benchmark functions!"
}

check_var_path_exists
cleanup
install
benchmark
