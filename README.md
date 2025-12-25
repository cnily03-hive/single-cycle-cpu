# Single-Cycle CPU

[![Issues](https://img.shields.io/github/issues-raw/cnily03-hive/single-cycle-cpu)](https://github.com/cnily03-hive/single-cycle-cpu/issues)
[![Stars](https://img.shields.io/github/stars/cnily03-hive/single-cycle-cpu)](https://github.com/cnily03-hive/single-cycle-cpu/stargazers)
[![License](https://img.shields.io/github/license/cnily03-hive/single-cycle-cpu)](https://github.com/cnily03-hive/single-cycle-cpu?tab=MIT-1-ov-file)

This project is a simple verilog project to implement a single-cycle CPU. The CPU is based on the 32-bit MIPS instruction set under Harvard architecture. The CPU is designed to be able to run on FPGA board.

For course report, see [docs/course-report.pdf](./docs/course-report.pdf).

## Instruction Set

| Type | Instruction | <center>Description</center> |
| :--: | :---------: | :---------- |
| R    | `add`       | Add |
| R    | `addu`      | Add Unsigned |
| R    | `sub`       | Subtract |
| R    | `subu`      | Subtract Unsigned |
| R    | `and`       | Bitwise AND |
| R    | `or`        | Bitwise OR |
| R    | `xor`       | Bitwise XOR |
| R    | `sll`       | Shift Left Logical |
| R    | `srl`       | Shift Right Logical |
| R    | `sra`       | Shift Right Arithmetic |
| I    | `addi`      | Add Immediate |
| I    | `addiu`     | Add Immediate Unsigned |
| I    | `andi`      | Bitwise AND Immediate |
| I    | `ori`       | Bitwise OR Immediate |
| I    | `lw`        | Load Word |
| I    | `sw`        | Store Word |
| I    | `beq`       | Branch on Equal |
| I    | `bne`       | Branch on Not Equal |
| J    | `j`         | Jump |
| ...  | ...         | ... |

## Usage

Edit the instruction file `inst.asm` in directory of `test/`.

> [!Note]
> The first line of instruction may not be run. The duration of the first PC, which is initialized with `0x00000000`, is shorter than one clock cycle time. During this short time caused by the positive edge of clock given at the very beginning, other components would finished initializing, and then wait for the next positive edge of clock and to trigger PC adding 4.

The command `make inst` will generate the hexadecimal instruction file `inst.hex` from `inst.asm` at the same directory. A derived online tool [asm.tampoo.io](https://asm.tampoo.io) is developed for this purpose.

As the code snippet in `io/InstMem.v` shows, the instruction memory is initialized with the hexadecimal instruction file `inst.hex`.

```verilog
initial begin
    $readmemh("test/inst.hex", MEM_DATA);
end
```

Similarly, the data memory is initialized with the hexadecimal data file `data.hex`, as the code snippet in `io/DataMem.v` will load the data file `data.hex` into the data memory.

```verilog
initial begin
    $readmemh("test/data.hex", MEM_DATA);
end
```

The example instruction file offered in `test` directory solves the problem of whether a year is a leap year. The year number is loaded from the address of `0x00000000` in data memory, and the result (`0` for no, `1` for yes) will be saved at the address of `0x00000008` in data memory.

## Development

This project offers a [Makefile](Makefile). Run `make help` for usage.

```plaintext
Usage:
  make            - Transform instruction file and run test
  make help       - Show this help message
  make inst       - Analyze instruction file only
  make test       - Run test only
  make clean      - Remove build artifacts (*.vvp, *.vcd, *.out)
  make <file>     - Simulate specified verilog file
       <file>.vvp
```

For simulation, make sure the following packages are installed on your system:

- [iverilog](https://github.com/steveicarus/iverilog)
- [GTKWave](https://github.com/gtkwave/gtkwave)

On Ubuntu/Debian-like linux, they can be easily installed:

```shell
apt-get install -y iverilog gtkwave
```

The `make inst` runs a JS script. Make sure you have any JavaScript runtime installed. `node` is taken default in [Makefile](Makefile).

Devcontainer is provided with recommended environment configured. You can launch a container on your IDE or create a codespace.

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/cnily03-hive/single-cycle-cpu?quickstart=1)

## Simulation

Run `make test` to simulate the CPU. If the wave cannot meet the needs, modify the following fields at the top of the file `top_sim_testbench.v`.

```verilog
`define N_CLOCKS  10'd500
`define N_OPERATE $stop
```

For example, you can modify `N_CLOCKS` to `10'd100` to simulate the CPU per 100 clocks, then enter `cont` in the terminal prompt to continue next 100 clocks of simulation.

You can modify `N_OPERATE` to `$finish` to finish and exit the simulation after N_CLOCKS clocks. In [vvp flags](https://steveicarus.github.io/iverilog/usage/vvp_flags.html), option `-n` means `non-interactive ($stop = $finish)`, you can also comment the following line in [Makefile](Makefile).

```shell
VVP_FLAGS := -n
```

## Hardware Testing

Top module `TOP_TouchDisplay` (at `top_touch_display.v`), which depends on `constraints.xdc` as the constraint file and `lcd_module.dcp` as its display IP core, is designed and test on **LOONGSON FPGA Board (FPGA-A7-PRJ-UDB XC7A200T-FBG676-2)**.

For hardware testing, instance `cpu_rf` in module `Regfile` has exposed `test_addr` and `test_data`, in order that we can see the register file's content on the touch screen. To remove these two ports, just remove all the lines or blocks in this project with comment `? TEST INTERFACE`.

File `top_touch_display.v` allows you to input value into data memory, and meanwhile to read the data memory's content. At the top of the file, edit the following fields to change the address of input and output.

```verilog
`define INPUT1_ADDR  32'b0000
`define INPUT2_ADDR  32'b0100
`define OUTPUT1_ADDR 32'b1000
`define OUTPUT2_ADDR 32'b1100
```

The first input value will be saved at the address of `INPUT1_ADDR`, and the second input value will be saved at the address of `INPUT2_ADDR`. When you touch OK on the touch screen, the value will be automatically saved into the corresponding address of data memory. The content of the address of `OUTPUT1_ADDR` and `OUTPUT2_ADDR` will be displayed on the touch screen.

The top module for this FPGA board also implements button control.

| Button    | Variable    | <center>Description</center> |
| :-------: | :---------: | :---------- |
|  SW18     | `input_sel` | `0` to input for `INPUT1_ADDR`, `1` to input for `INPUT2_ADDR` |
|  SW20     | `cont_clk`  | `0` to use button single trigger, `1` to use continuous trigger |
|  SW_STEP0 | `btn_clkn`  | Press to trigger CPU clock (disabled when `cont_clk` is `1`) (Button Debounced) |
|  SW_STEP1 | `cpu_rstn`  | Press to reset the CPU (PC and Register File) (Button Debounced) |
|  FPGA_RST | /           | Reset the touch screen (clear input, but not mean to clear Data Memory) |

As well as LED display.

| LED       | Variable       | <center>Description</center> |
| :-------: | :------------: | :---------- |
| LED1      | `led_cout_rst` | The reset signal (high level active) |
| LED2      | `led_cout_clk` | The clock signal of CPU (high level active) |

The basic clock frequency is 100 MHz. The CPU clock is 1 MHz. Debounce time is 10 ms.

## References

- FPGA board product by [Loongson](http://www.loongson.cn)
- [Vivado Design Suite](https://www.xilinx.com/products/design-tools/vivado.html) by [Xilinx](https://www.xilinx.com)
- Video [MIPS单周期CPU设计 | Verilog](https://bilibili.com/video/BV1rD4y1D7h9)

## License

CopyRight (c) Cnily03. All rights reserved.

Licensed under the [MIT](./LICENSE) License.
