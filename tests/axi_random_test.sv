`ifndef AXI_RANDOM_TEST_SV
`define AXI_RANDOM_TEST_SV

class axi_random_test extends axi_base_test;

    // Register with the UVM Factory
    `uvm_component_utils(axi_random_test)

    // Constructor

    function new(string name = "axi_random_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // Run Phase (Where the action happens)

    task run_phase(uvm_phase phase);
        axi_random_seq rand_seq;

        // 1. Raise objection to keep simulation alive
        phase.raise_objection(this, "Starting random sequence");
        
        `uvm_info("TEST_START", "Executing AXI4-Lite Random Stress Test...", UVM_LOW)

        // 2. Create the sequence
        rand_seq = axi_random_seq::type_id::create("rand_seq");

        // 3. Start the sequence on our environment's sequencer
        // (env is instantiated in the base class)
        if (env.agent.sequencer != null) begin
            rand_seq.start(env.agent.sequencer);
        end else begin
            `uvm_fatal("TEST_FAIL", "Sequencer handle is null!")
        end

        `uvm_info("TEST_DONE", "Random sequence finished.", UVM_LOW)

        // 4. Drop objection to allow simulation to proceed to extraction/reporting phases
        phase.drop_objection(this, "Random sequence complete");
    endtask

endclass : axi_random_test

`endif 
