`ifndef AXI_DIRECTED_TESTS_SV
`define AXI_DIRECTED_TESTS_SV

// Test 1: Write/Readback & Reserved Bits

class axi_readback_test extends axi_base_test;
    `uvm_component_utils(axi_readback_test)
    function new(string name = "axi_readback_test", uvm_component parent = null); super.new(name, parent); endfunction

    task run_phase(uvm_phase phase);
        axi_write_readback_seq seq = axi_write_readback_seq::type_id::create("seq");
        phase.raise_objection(this);
        seq.reg_model = env.reg_model;
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask
endclass

// Test 2: Permissions (RO/WO)

class axi_permission_test extends axi_base_test;
    `uvm_component_utils(axi_permission_test)
    function new(string name = "axi_permission_test", uvm_component parent = null); super.new(name, parent); endfunction

    task run_phase(uvm_phase phase);
        axi_permission_seq seq = axi_permission_seq::type_id::create("seq");
        phase.raise_objection(this);
        seq.reg_model = env.reg_model;
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask
endclass

// Test 3: Byte Strobe

class axi_strobe_test extends axi_base_test;
    `uvm_component_utils(axi_strobe_test)
    function new(string name = "axi_strobe_test", uvm_component parent = null); super.new(name, parent); endfunction

    task run_phase(uvm_phase phase);
        axi_byte_strobe_seq seq = axi_byte_strobe_seq::type_id::create("seq");
        phase.raise_objection(this);
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask
endclass

// Test 4: Mid-Transaction Reset

class axi_reset_test extends axi_base_test;
    `uvm_component_utils(axi_reset_test)
    function new(string name = "axi_reset_test", uvm_component parent = null); super.new(name, parent); endfunction

    task run_phase(uvm_phase phase);
        axi_mid_reset_seq seq = axi_mid_reset_seq::type_id::create("seq");
        phase.raise_objection(this);
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask
endclass

// Test 5: AW Arrives Before W

class axi_aw_before_w_test extends axi_base_test;
    `uvm_component_utils(axi_aw_before_w_test)
    function new(string name = "axi_aw_before_w_test", uvm_component parent = null); super.new(name, parent); endfunction

    task run_phase(uvm_phase phase);
        axi_aw_before_w_seq seq = axi_aw_before_w_seq::type_id::create("seq");
        phase.raise_objection(this);
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask
endclass

// Test 6: W Arrives Before AW

class axi_w_before_aw_test extends axi_base_test;
    `uvm_component_utils(axi_w_before_aw_test)
    function new(string name = "axi_w_before_aw_test", uvm_component parent = null); super.new(name, parent); endfunction

    task run_phase(uvm_phase phase);
        axi_w_before_aw_seq seq = axi_w_before_aw_seq::type_id::create("seq");
        phase.raise_objection(this);
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask
endclass

// Test 7: Heavy Master Backpressure

class axi_backpressure_test extends axi_base_test;
    `uvm_component_utils(axi_backpressure_test)
    function new(string name = "axi_backpressure_test", uvm_component parent = null); super.new(name, parent); endfunction

    task run_phase(uvm_phase phase);
        axi_backpressure_seq seq = axi_backpressure_seq::type_id::create("seq");
        phase.raise_objection(this);
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask
endclass

`endif 