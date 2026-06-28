`ifndef AXI_RANDOM_SEQ_SV
`define AXI_RANDOM_SEQ_SV

class axi_random_seq extends uvm_sequence #(axi_seq_item);

    `uvm_object_utils(axi_random_seq)

    rand int num_transactions;
    
    constraint c_trans {
        num_transactions inside {[50:100]};
    }

    function new(string name = "axi_random_seq");
        super.new(name);
    endfunction

    virtual task body();
        axi_seq_item req;

        `uvm_info("SEQ_START", $sformatf("Starting random sequence with %0d transactions...", num_transactions), UVM_LOW)

        for (int i = 0; i < num_transactions; i++) begin
            req = axi_seq_item::type_id::create("req");
            
            start_item(req);
            if (!req.randomize()) begin
                `uvm_fatal("SEQ_RAND_FAIL", "Failed to randomize axi_seq_item")
            end
            
            if (req.illegal_access) begin
                `uvm_info("SEQ_INJECT", "Injecting intentional out-of-bounds access to test SLVERR", UVM_HIGH)
            end
            if (req.inject_backpressure) begin
                `uvm_info("SEQ_INJECT", "Injecting heavy master backpressure", UVM_HIGH)
            end

            finish_item(req);
        end

        `uvm_info("SEQ_DONE", "Random sequence completed.", UVM_LOW)
    endtask

endclass : axi_random_seq

`endif 