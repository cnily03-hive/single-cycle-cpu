# Single Cycle CPU

## Introduction

This project is a simple verilog project to impliment a single cycle CPU. The CPU is based on the MIPS instruction set on 32-bit architecture.

## Usage

This project offers a make tool. Some of the commands are listed below.

- `./make`

  Equal to `./make hexinst && ./make test`

- `./make test`

  Compile and run the testbench (default: `top_sim_testbench.v`)

- `./make <file>` or `./make <file>.v`

  Compile and run the specified verilog file

- `./make clean`

  Remove all the generated files

- `./make hexinst`

  Generate the hexadecimal instruction file from file `inst.bin`
