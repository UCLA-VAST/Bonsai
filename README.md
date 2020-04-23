# Bonsai
This repository lists various fundamental merger tree configurations of Bonsai.

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

Since hardware emulation only supports a default device, so you may also need to change line 80 in `src/host.cpp` and speficy  `device[0]`.

```base
cl::Device device = devices[0];
```

To run hardware emulation, please type

```base
make check TARGET=hw_emu DEVICE=<FPGA platform>
```

### Hardware test

For hardware on-board test, you need to generate the bitstream first using the following command.

```base
make all TARGET=hw DEVICE=<FPGA platform>
```

## Project Folder Structure



##Platform support

