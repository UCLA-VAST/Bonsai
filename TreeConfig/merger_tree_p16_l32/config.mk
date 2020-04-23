VIVADO := $(XILINX_VIVADO)/bin/vivado
$(TEMP_DIR)/merger_tree_p16_l32_i64_mb.xo: src/kernel.xml scripts/package_kernel.tcl scripts/gen_xo.tcl src/hdl/*.sv src/hdl/*.v 
	mkdir -p $(TEMP_DIR)
	$(VIVADO) -mode batch -source scripts/gen_xo.tcl -tclargs $(TEMP_DIR)/merger_tree_p16_l32_i64_mb.xo merger_tree_p16_l32_i64_mb $(TARGET) $(DEVICE) $(XSA)
