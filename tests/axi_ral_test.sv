`ifndef AXI_RAL_TEST_SV
`define AXI_RAL_TEST_SV

class axi_ral_test extends axi_base_test;

    `uvm_component_utils(axi_ral_test)

    function new(string name = "axi_ral_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        axi_ral_seq ral_seq;

        // 1. Raise objection
        phase.raise_objection(this, "Starting RAL sequence");
        `uvm_info("TEST_START", "Executing AXI4-Lite RAL Verification Test...", UVM_LOW)

        // 2. Create the sequence
        ral_seq = axi_ral_seq::type_id::create("ral_seq");

        // 3. Hand the sequence the pointer to the Register Model!
        ral_seq.reg_model = env.reg_model;

        // 4. Start the sequence
        if (env.agent.sequencer != null) begin
            ral_seq.start(env.agent.sequencer);
        end else begin
            `uvm_fatal("TEST_FAIL", "Sequencer handle is null!")
        end

        `uvm_info("TEST_DONE", "RAL sequence finished.", UVM_LOW)
        phase.drop_objection(this, "RAL sequence complete");
    endtask

endclass : axi_ral_test

`endif 
