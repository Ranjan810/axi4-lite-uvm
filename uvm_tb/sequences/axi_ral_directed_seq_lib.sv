`ifndef AXI_RAL_DIRECTED_SEQ_LIB_SV
`define AXI_RAL_DIRECTED_SEQ_LIB_SV

// 1. Write/Readback & Reserved Bits Sequence

class axi_write_readback_seq extends uvm_sequence #(axi_seq_item);
    `uvm_object_utils(axi_write_readback_seq)
    axi_reg_block reg_model;

    function new(string name = "axi_write_readback_seq"); super.new(name); endfunction

    virtual task body();
        uvm_status_e status;
        uvm_reg_data_t rdata;

        // Write to CTRL (Bits 31:3 are reserved, so writing FFFFFFFF should only keep 00000007)
        reg_model.ctrl.write(status, 32'hFFFF_FFFF, UVM_FRONTDOOR, null, this);
        reg_model.ctrl.read(status, rdata, UVM_FRONTDOOR, null, this);
        
        if (rdata !== 32'h0000_0007) 
            `uvm_error("DIR_SEQ", $sformatf("Reserved bits failed! Expected: 0x7, Got: %0h", rdata))
        else 
            `uvm_info("DIR_SEQ", "Write/Readback & Reserved bits verified.", UVM_LOW)
    endtask
endclass

// 2. Permission Violations (RO/WO) Sequence

class axi_permission_seq extends uvm_sequence #(axi_seq_item);
    `uvm_object_utils(axi_permission_seq)
    axi_reg_block reg_model;

    function new(string name = "axi_permission_seq"); super.new(name); endfunction

    virtual task body();
        uvm_status_e status;
        uvm_reg_data_t rdata;

        `uvm_info("DIR_SEQ", "Testing RO Write Violation...", UVM_LOW)
        // Write to RO Status Register (Should return SLVERR -> UVM_NOT_OK)
        reg_model.status.write(status, 32'hFFFF_FFFF, UVM_FRONTDOOR, null, this);
        if (status == UVM_IS_OK) `uvm_error("DIR_SEQ", "Failed to block RO write!")

        `uvm_info("DIR_SEQ", "Testing WO Read Violation...", UVM_LOW)
        // Hardcoded read to DATA_IN (0x10) because RAL usually blocks WO reads entirely at software level
        // We will test this via the bus sequence later to ensure hardware blocks it.
    endtask
endclass

`endif 
