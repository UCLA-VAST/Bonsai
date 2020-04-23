# Bonsai
This repository lists various fundamental merger tree configurations of Bonsai.

##Testing

We provide a simple random data generator in the merger_tree_p*l*/data/datagen.c, which will generate `2^N` elements. The following commands show an example of generating a random dataset callded "data_1^20.txt" with 1M elements.

```bash
cd TreeConfig/merger_tree_p4_l4/data/
gcc -o datagen datagen.c
./datagen 20
```

For hardware emulation, change the Makefile correspondingly. 

```bash
check: all
ifeq ($(TARGET),$(filter $(TARGET),sw_emu hw_emu))
ifeq ($(HOST_ARCH), x86)
	$(CP) $(EMCONFIG_DIR)/emconfig.json .
	XCL_EMULATION_MODE=$(TARGET) ./$(EXECUTABLE) $(BUILD_DIR)/merger_tree_p*_l*.xclbin ./data/data_1^N.txt N
else
```



##Platform support

