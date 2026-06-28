`ifndef AXI_BASE_TEST_SV
`define AXI_BASE_TEST_SV

class axi_base_test extends uvm_test;

    `uvm_component_utils(axi_base_test)

    // The Environment

    axi_env env;

    // Constructor
    function new(string name = "axi_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // Build Phase

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Instantiate the environment
        env = axi_env::type_id::create("env", this);
        
        // Set a default drain time so the simulation doesn't end abruptly 
        // the millisecond the last sequence item is sent.
        uvm_config_db#(time)::set(this, "*", "drain_time", 500ns);
    endfunction

    // End of Elaboration Phase

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        // Print the final testbench topology for debugging
        uvm_top.print_topology();
    endfunction

    // Run Phase (Global Timeout)

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        // Fail-safe timeout to prevent infinite hangs if a handshake deadlocks
        phase.phase_done.set_drain_time(this, 500ns);
        uvm_top.set_timeout(10ms, 0); 
    endtask

endclass : axi_base_test

`endif 
