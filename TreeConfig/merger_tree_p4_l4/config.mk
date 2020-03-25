VIVADO := $(XILINX_VIVADO)/bin/vivado
$(TEMP_DIR)/merger_tree_p4_l4_i8.xo: src/kernel.xml scripts/package_kernel.tcl scripts/gen_xo.tcl src/hdl/*.sv src/hdl/*.v 
	mkdir -p $(TEMP_DIR)
	$(VIVADO) -mode batch -source scripts/gen_xo.tcl -tclargs $(TEMP_DIR)/merger_tree_p4_l4_i8.xo merger_tree_p4_l4_i8 $(TARGET) $(DEVICE) $(XSA)
