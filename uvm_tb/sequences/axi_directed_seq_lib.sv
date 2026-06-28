`ifndef AXI_DIRECTED_SEQ_LIB_SV
`define AXI_DIRECTED_SEQ_LIB_SV

// Sequence 1: AW Arrives Before W

class axi_aw_before_w_seq extends axi_random_seq;
    `uvm_object_utils(axi_aw_before_w_seq)

    function new(string name = "axi_aw_before_w_seq");
        super.new(name);
    endfunction

    virtual task body();
        axi_seq_item req;
        `uvm_info("DIR_SEQ", "Starting AW-Before-W Sequence...", UVM_LOW)
        for (int i = 0; i < 20; i++) begin
            req = axi_seq_item::type_id::create("req");
            start_item(req);
            
            // Override constraints inline to force timing order
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

// Sequence 2: W Arrives Before AW

class axi_w_before_aw_seq extends axi_random_seq;
    `uvm_object_utils(axi_w_before_aw_seq)

    function new(string name = "axi_w_before_aw_seq");
        super.new(name);
    endfunction

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

// Sequence 3: Heavy Master Backpressure

class axi_backpressure_seq extends axi_random_seq;
    `uvm_object_utils(axi_backpressure_seq)

    function new(string name = "axi_backpressure_seq");
        super.new(name);
    endfunction

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

`endif 
