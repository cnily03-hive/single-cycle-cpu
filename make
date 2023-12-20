#!/bin/bash

TOP_VERILOG_FILE="top_sim_testbench"
INST_BIN_FILE="test/inst.bin"

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

function hexinst() {
    node bin2hex.js "$INST_BIN_FILE"
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
elif [ "$1" == "hexinst" ]; then
    printmsg "Generating hexadecimal instruction file..."
    hexinst && \
    exit 0
elif [ "$1" == "test" ]; then
    printmsg "Running test..."
    run_test "$TOP_VERILOG_FILE" && \
    exit 0
elif [ "$1" == "" ]; then
    printmsg "Generating hexadecimal instruction file..." && \
    hexinst && \
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