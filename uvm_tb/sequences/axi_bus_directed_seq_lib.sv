`ifndef AXI_BUS_DIRECTED_SEQ_LIB_SV
`define AXI_BUS_DIRECTED_SEQ_LIB_SV

// 1. Byte Strobe (WSTRB) Sequence

class axi_byte_strobe_seq extends uvm_sequence #(axi_seq_item);
    `uvm_object_utils(axi_byte_strobe_seq)

    function new(string name = "axi_byte_strobe_seq"); super.new(name); endfunction

    virtual task body();
        axi_seq_item req;
        bit [3:0] strobes [4] = '{4'b0001, 4'b0010, 4'b0100, 4'b1000};

        `uvm_info("DIR_SEQ", "Testing individual byte strobes...", UVM_LOW)
        foreach (strobes[i]) begin
            req = axi_seq_item::type_id::create("req");
            start_item(req);
            if (!req.randomize() with {
                op == AXI_WRITE;
                addr == 32'h1C; // CFG_REG 0
                strb == strobes[i];
                illegal_access == 0;
            }) `uvm_fatal("SEQ_ERR", "Rand failed")
            finish_item(req);
        end
    endtask
endclass

// 2. AW Arrives Before W

class axi_aw_before_w_seq extends axi_random_seq;
    `uvm_object_utils(axi_aw_before_w_seq)
    function new(string name = "axi_aw_before_w_seq"); super.new(name); endfunction

    virtual task body();
        axi_seq_item req;
        `uvm_info("DIR_SEQ", "Starting AW-Before-W Sequence...", UVM_LOW)
        for (int i = 0; i < 20; i++) begin
            req = axi_seq_item::type_id::create("req");
            start_item(req);
            if (!req.randomize() with {
                op == AXI_WRITE;
                aw_delay == 0;
                w_delay == 5; // Force W to arrive 5 cycles later
                inject_backpressure == 0;
                illegal_access == 0;
            }) `uvm_fatal("SEQ_ERR", "Randomization failed")
            finish_item(req);
        end
    endtask
endclass

// 3. W Arrives Before AW

class axi_w_before_aw_seq extends axi_random_seq;
    `uvm_object_utils(axi_w_before_aw_seq)
    function new(string name = "axi_w_before_aw_seq"); super.new(name); endfunction

    virtual task body();
        axi_seq_item req;
        `uvm_info("DIR_SEQ", "Starting W-Before-AW Sequence...", UVM_LOW)
        for (int i = 0; i < 20; i++) begin
            req = axi_seq_item::type_id::create("req");
            start_item(req);
            if (!req.randomize() with {
                op == AXI_WRITE;
                aw_delay == 5; // Force AW to arrive 5 cycles later
                w_delay == 0;  
                inject_backpressure == 0;
                illegal_access == 0;
            }) `uvm_fatal("SEQ_ERR", "Randomization failed")
            finish_item(req);
        end
    endtask
endclass

// 4. Simultaneous AW/W Sequence

class axi_simultaneous_aw_w_seq extends uvm_sequence #(axi_seq_item);
    `uvm_object_utils(axi_simultaneous_aw_w_seq)
    function new(string name = "axi_simultaneous_aw_w_seq"); super.new(name); endfunction

    virtual task body();
        axi_seq_item req;
        for (int i = 0; i < 5; i++) begin
            req = axi_seq_item::type_id::create("req");
            start_item(req);
            if (!req.randomize() with {
                op == AXI_WRITE;
                aw_delay == 0; // Both arrive at exact same cycle
                w_delay == 0;
            }) `uvm_fatal("SEQ_ERR", "Rand failed")
            finish_item(req);
        end
    endtask
endclass

// 5. Heavy Master Backpressure

class axi_backpressure_seq extends axi_random_seq;
    `uvm_object_utils(axi_backpressure_seq)
    function new(string name = "axi_backpressure_seq"); super.new(name); endfunction

    virtual task body();
        axi_seq_item req;
        `uvm_info("DIR_SEQ", "Starting Heavy Backpressure Sequence...", UVM_LOW)
        for (int i = 0; i < 20; i++) begin
            req = axi_seq_item::type_id::create("req");
            start_item(req);
            if (!req.randomize() with {
                inject_backpressure == 1; // Forces BREADY and RREADY delays to 5-15 cycles
                idle_cycles == 0;
            }) `uvm_fatal("SEQ_ERR", "Randomization failed")
            finish_item(req);
        end
    endtask
endclass

// 6. Mid-Transaction Reset Sequence

class axi_mid_reset_seq extends uvm_sequence #(axi_seq_item);
    `uvm_object_utils(axi_mid_reset_seq)
    function new(string name = "axi_mid_reset_seq"); super.new(name); endfunction

    virtual task body();
        axi_seq_item req;
        
        req = axi_seq_item::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {random_reset == 0; op == AXI_WRITE;});
        finish_item(req);

        `uvm_info("DIR_SEQ", "Firing Mid-Transaction Reset!", UVM_LOW)
        req = axi_seq_item::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {random_reset == 1;});
        finish_item(req);

        req = axi_seq_item::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {random_reset == 0; op == AXI_READ;});
        finish_item(req);
    endtask
endclass

`endif 
