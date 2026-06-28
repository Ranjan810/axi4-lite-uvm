`ifndef AXI_RAL_SEQ_SV
`define AXI_RAL_SEQ_SV

class axi_ral_seq extends uvm_sequence #(axi_seq_item);

    `uvm_object_utils(axi_ral_seq)

    axi_reg_block reg_model;

    function new(string name = "axi_ral_seq");
        super.new(name);
    endfunction

    virtual task body();
        uvm_status_e status;
        uvm_reg_data_t rdata;

        if (reg_model == null) begin
            `uvm_fatal("RAL_SEQ", "Register model handle is null. Must be assigned before starting sequence.")
        end

        `uvm_info("RAL_SEQ", "Starting RAL Verification Sequence...", UVM_LOW)

        // 1. Write to the Control Register
        `uvm_info("RAL_SEQ", "Writing to CTRL register...", UVM_LOW)
        reg_model.ctrl.write(status, 32'h0000_0007, UVM_FRONTDOOR, null, this);

        // 2. Read back the Control Register
        reg_model.ctrl.read(status, rdata, UVM_FRONTDOOR, null, this);
        `uvm_info("RAL_SEQ", $sformatf("Read from CTRL: %0h", rdata), UVM_LOW)

        // 3. Write to a Config Register
        `uvm_info("RAL_SEQ", "Writing to CFG_REGS[0]...", UVM_LOW)
        reg_model.cfg_regs[0].write(status, 32'hDEAD_BEEF, UVM_FRONTDOOR, null, this);
        
        // 4. Test W1C (Write 1 to Clear) on IRQ Status
        `uvm_info("RAL_SEQ", "Clearing IRQ Status flags...", UVM_LOW)
        reg_model.irq_status.write(status, 32'hFFFF_FFFF, UVM_FRONTDOOR, null, this);

        // 5. Try to write to a Read-Only Register (Should generate SLVERR in scoreboard)
        `uvm_info("RAL_SEQ", "Attempting illegal write to STATUS (RO)...", UVM_LOW)
        reg_model.status.write(status, 32'hFFFF_FFFF, UVM_FRONTDOOR, null, this);

        `uvm_info("RAL_SEQ", "RAL Verification Sequence Complete.", UVM_LOW)
    endtask

endclass : axi_ral_seq

`endif 
