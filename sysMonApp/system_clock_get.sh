#!/bin/bash

export DEVICE_SERIAL='10.136.8.1:5555'

export target_cpu_debug_path='/sys/devices/system/cpu'

function init() {
    echo '(**) Mount debug partition'
    adb -s ${DEVICE_SERIAL} wait-for-device root
    adb -s ${DEVICE_SERIAL} wait-for-device remount
    adb -s ${DEVICE_SERIAL} wait-for-device root
    adb -s ${DEVICE_SERIAL} shell mount -t debugfs none /sys/kernel/debug
    echo '(**) Debug mounted...'
}

function get_qrb5165_cpu_clk() {

    # Kyro 585 Prime @ 2.84GHz 
    cpu_clk_cpu0=$(adb -s ${DEVICE_SERIAL} shell cat ${target_cpu_debug_path}/cpu7/cpufreq/scaling_cur_freq | tr -d '\r\n')

    # Kyro 585 Gold @ 2.42GHz 
    cpu_clk_cpu1=$(adb -s ${DEVICE_SERIAL} shell cat ${target_cpu_debug_path}/cpu4/cpufreq/scaling_cur_freq | tr -d '\r\n')
    cpu_clk_cpu2=$(adb -s ${DEVICE_SERIAL} shell cat ${target_cpu_debug_path}/cpu5/cpufreq/scaling_cur_freq | tr -d '\r\n')
    cpu_clk_cpu3=$(adb -s ${DEVICE_SERIAL} shell cat ${target_cpu_debug_path}/cpu6/cpufreq/scaling_cur_freq | tr -d '\r\n')

    # Kyro 585 Silver @ 1.80GHz
    cpu_clk_cpu4=$(adb -s ${DEVICE_SERIAL} shell cat ${target_cpu_debug_path}/cpu0/cpufreq/scaling_cur_freq | tr -d '\r\n')
    cpu_clk_cpu5=$(adb -s ${DEVICE_SERIAL} shell cat ${target_cpu_debug_path}/cpu1/cpufreq/scaling_cur_freq | tr -d '\r\n')
    cpu_clk_cpu6=$(adb -s ${DEVICE_SERIAL} shell cat ${target_cpu_debug_path}/cpu2/cpufreq/scaling_cur_freq | tr -d '\r\n')
    cpu_clk_cpu7=$(adb -s ${DEVICE_SERIAL} shell cat ${target_cpu_debug_path}/cpu3/cpufreq/scaling_cur_freq | tr -d '\r\n')

    now=$(date '+%d-%m-%y %T')

    echo "############ Current CPU ${now} ############"
    echo "# CPU 0 (Prime)  @ 2.84GHz: ${cpu_clk_cpu0} Hz"
    echo "#"
    echo "# CPU 1 (Gold)   @ 2.42GHz: ${cpu_clk_cpu1} Hz"
    echo "#     2                   : ${cpu_clk_cpu2} Hz"
    echo "#     3                   : ${cpu_clk_cpu3} Hz"
    echo "#"
    echo "# CPU 4 (Silver) @ 1.80GHz: ${cpu_clk_cpu4} Hz"
    echo "#     5                   : ${cpu_clk_cpu5} Hz"
    echo "#     6                   : ${cpu_clk_cpu6} Hz"
    echo "#     7                   : ${cpu_clk_cpu7} Hz"
    echo "########################################################"

}

function get_qrb5165_npu_clk() {

    # Control Processor
    npu_cp_clk_curr=$(adb -s ${DEVICE_SERIAL} shell cat /sys/kernel/debug/clk/npu_cc_core_clk/clk_measure | tr -d '\r\n')
    npu_cp_clk_vote=$(adb -s ${DEVICE_SERIAL} shell cat /sys/kernel/debug/clk/npu_cc_core_clk/clk_rate | tr -d '\r\n')

    # Data Plan Engine (DP)
    npu_dp0_clk_curr=$(adb -s ${DEVICE_SERIAL} shell cat /sys/kernel/debug/clk/npu_cc_cal_hm0_clk/clk_measure | tr -d '\r\n')
    npu_dp0_clk_vote=$(adb -s ${DEVICE_SERIAL} shell cat /sys/kernel/debug/clk/npu_cc_cal_hm0_clk/clk_rate | tr -d '\r\n')
    npu_dp1_clk_curr=$(adb -s ${DEVICE_SERIAL} shell cat /sys/kernel/debug/clk/npu_cc_cal_hm1_clk/clk_measure | tr -d '\r\n')
    npu_dp1_clk_vote=$(adb -s ${DEVICE_SERIAL} shell cat /sys/kernel/debug/clk/npu_cc_cal_hm1_clk/clk_rate | tr -d '\r\n')

    now=$(date '+%d-%m-%y %T')

    echo "############ Current NPU ${now} ############"
    echo "# NPU Control Measure: ${npu_cp_clk_curr} Hz"
    echo "# NPU Control Rate   : ${npu_cp_clk_vote} Hz"
    echo "#"
    echo "# NPU DP0 Measure: ${npu_dp0_clk_curr} Hz"
    echo "# NPU DP0 Rate   : ${npu_dp0_clk_vote} Hz"
    echo "# NPU DP1 Measure: ${npu_dp1_clk_curr} Hz"
    echo "# NPU DP1 Rate   : ${npu_dp1_clk_vote} Hz"
    echo "########################################################"
}

function get_qrb5165_cdsp_clk() {

    # sysMonApp

    # SNoC: System Network on Chip
    # BIMC: Bus Integrated Memory Controller
    # MemNoc: Memory Network on Chip
    
    cdsp_clk_core='1234'
    cdsp_clk_snoc_vote=''
    cdsp_clk_snoc_curr=''
    cdsp_clk_memnoc_vote=''
    cdsp_clk_bimc_curr=''

    lines=$(adb -s ${DEVICE_SERIAL} shell /data/sysMonApp getstate --q6 cdsp)
    while read -r line
    do
        if [[ $line == *"DSP Core clock"* ]]; then
            cdsp_clk_core=$(echo ${line#*:} | tr -d '\r\n')
        fi
        if [[ $line == *"SNOC Vote"* ]]; then
            cdsp_clk_snoc_vote_core=$(echo ${line#*:} | tr -d '\r\n')
        fi
        if [[ $line == *"MEMNOC Vote"* ]]; then
            cdsp_clk_memnoc_vote=$(echo ${line#*:} | tr -d '\r\n')
        fi
        if [[ $line == *"Measured SNOC"* ]]; then
            cdsp_clk_snoc_curr=$(echo ${line#*:} | tr -d '\r\n')
        fi
        if [[ $line == *"Measured BIMC"* ]]; then
            cdsp_clk_bimc_curr=$(echo ${line#*:} | tr -d '\r\n')
        fi

    done <<< "$lines"

    now=$(date '+%d-%m-%y %T')

    echo "############ Current CDSP ${now} ############"
    echo "# cDSP Core    : $cdsp_clk_core"
    echo "# SNOC Vote    : $cdsp_clk_snoc_vote_core"
    echo "# MEMNOC Vote  : $cdsp_clk_memnoc_vote"
    echo "# SNOC Measured: $cdsp_clk_snoc_curr"
    echo "# BIMC Measured: $cdsp_clk_bimc_curr"
    echo "########################################################"

    # /data/local/tmp/sysMonApp getPowerStats --q6 cdsp && sleep 300 && /data/local/tmp/sysMonApp getPowerStats --q6 cdsp &
}

function get_qrb5165_gpu_clk() {

    gpu_clk_opengl_core_curr=$(adb -s ${DEVICE_SERIAL} shell cat /sys/kernel/debug/clk/measure_only_gpu_cc_gx_gfx3d_clk/clk_measure)
    gpu_clk_opengl_core_vote=$(adb -s ${DEVICE_SERIAL} shell cat /sys/kernel/debug/clk/measure_only_gpu_cc_gx_gfx3d_clk/clk_rate)
    echo $gpu_clk_opengl_core_curr
    echo $gpu_clk_opengl_core_vote
}

init
while true
do
  get_qrb5165_cpu_clk
  get_qrb5165_npu_clk
  get_qrb5165_cdsp_clk
  get_qrb5165_gpu_clk
done