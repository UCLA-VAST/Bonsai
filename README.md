# Bonsai
This repository lists various fundamental merger tree configurations of Bonsai.

## Prerequisities

This directory supports both SDAccel 2018.3, SDAccel 2019.1, Vitis 2019.2. For better version control, we suggest you using the latest Vitis 2019.2 flow.

You may need to download the Vitis_Accel 2019.2 github directory from [Xilinx Github](https://github.com/Xilinx/Vitis_Accel_Examples.git). Then copy our Bonsai directory into its rtl_kernel folder.

## Testing

### Random data generator

We provide a simple random data generator in the merger_tree_p*l*/data/datagen.c, which will generate `2^N` elements. The following commands show an example of generating a random dataset callded "data_1^20.txt" with 1M elements.

```bash
cd TreeConfig/merger_tree_p4_l4/data/
gcc -o datagen datagen.c
./datagen 20
```

### Hardware simulation

For hardware emulation, you can specify the input testbech as well as the number of elements you want to sort by changing the Makefile correspondingly as below. 

```bash
check: all
ifeq ($(TARGET),$(filter $(TARGET),sw_emu hw_emu))
ifeq ($(HOST_ARCH), x86)
	$(CP) $(EMCONFIG_DIR)/emconfig.json .
	XCL_EMULATION_MODE=$(TARGET) ./$(EXECUTABLE) $(BUILD_DIR)/merger_tree_p*_l*.xclbin ./data/data_1^N.txt N
else
...
```

Since hardware emulation only supports a default device, so you may also need to change line 80 in `src/host.cpp` and speficy  `devices[0]`.

```bash
cl::Device device = devices[0];
```

To run hardware emulation, please type

```bash
make check TARGET=hw_emu DEVICE=<FPGA platform>
```

### On-board test

First, you need to find the taget platform installed on your serve by typing

```bash
xbutil list
```

Below is an example of available platforms 
```bash
 [0] 0000:d8:00.1 xilinx_u280_xdma_201920_3(ID=0x5e278820) user(inst=131)
 [1] 0000:af:00.1 xilinx_u250_xdma_201830_2(ID=0x5d14fbe6) user(inst=130)
 [2] 0000:5e:00.1 xilinx_u50_gen3x16_xdma_201920_3 user(inst=129)
 [3] 0000:3b:00.1 xilinx_u200_qdma_201920_1(ID=0x5dccb0ca) user(inst=128)
```

If we want to run on the Xilinx u250 platform, then change line 80 in `src/host.cpp` to speficy `devices[1]`.

For hardware on-board test, you need to generate the bitstream first using the following command. The default path of the generated bitstream is in folder `./build_dir.hw.<FPGA platform>`.

```bash
make all TARGET=hw DEVICE=<FPGA platform>
```

Then you may be able to run the on-board test as follows.
```bash
./host ./build_dir.hw.<FPGA platform> ./data/data_1^N.txt N
```

## Project Folder Structure



##Platform support

