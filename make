#!/bin/bash

TOP_VERILOG_FILE="top_sim_testbench"
INST_ASM_FILE="test/inst.asm"

IVERILOG_CC="iverilog"
VVP_CC="vvp"
RM_CC="rm -rf"

function printmsg() {
    echo -e "\033[36m$1\033[0m"
}

function printerror() {
    echo -e "\033[31m$1\033[0m"
}

function run_test() {
    $IVERILOG_CC -o "$1.vvp" \
        "$1.v" && \
    $VVP_CC "$1.vvp"
}

function transform() {
    node transform.js "$INST_ASM_FILE" $@
}

function clean() {
    $RM_CC *.vvp
    $RM_CC *.vcd
    $RM_CC *.out
}


if [ "$1" == "clean" ]; then
    printmsg "Cleaning..."
    clean && \
    exit 0
elif [ "$1" == "inst" ]; then
    printmsg "Analyzing instruction file..."
    transform ${@:2} && \
    exit 0
elif [ "$1" == "test" ]; then
    printmsg "Running test..."
    run_test "$TOP_VERILOG_FILE" && \
    exit 0
elif [ "$1" == "" ]; then
    printmsg "Analyzing instruction file..."
    transform ${@:2} && \
    printmsg "Running \"$TOP_VERILOG_FILE.v\" ..." && \
    run_test "$TOP_VERILOG_FILE" && \
    exit 0
else
    if [[ "$1" =~ \.v$ ]]; then
        TOP_VERILOG_FILE=${1%.*}
    else
        TOP_VERILOG_FILE=$1
    fi
    printmsg "Running \"$TOP_VERILOG_FILE.v\" ..." && \
    run_test "$TOP_VERILOG_FILE" && \
    exit 0
fi

printerror "\033[31mFailed\033[0m"
exit 1