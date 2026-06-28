`ifndef AXI_REGRESSION_TEST_SV
`define AXI_REGRESSION_TEST_SV

class axi_regression_test extends axi_base_test;
    `uvm_component_utils(axi_regression_test)

    function new(string name = "axi_regression_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        axi_ral_seq               seq_ral;
        axi_write_readback_seq    seq_rb;
        axi_permission_seq        seq_perm;
        axi_byte_strobe_seq       seq_strobe;
        axi_mid_reset_seq         seq_reset;
        axi_aw_before_w_seq       seq_aw_w;
        axi_w_before_aw_seq       seq_w_aw;
        axi_simultaneous_aw_w_seq seq_simult;
        axi_backpressure_seq      seq_bp;
        axi_random_seq            seq_rand;

        phase.raise_objection(this, "Starting Full Regression Suite");
        `uvm_info("REGR", "--- COMMENCING ULTIMATE REGRESSION SUITE ---", UVM_LOW)

        // 1. RAL & Register Verification
        seq_ral = axi_ral_seq::type_id::create("seq_ral");
        seq_ral.reg_model = env.reg_model;
        seq_ral.start(env.agent.sequencer);

        // 2. Directed: Readback & Reserved Bits
        seq_rb = axi_write_readback_seq::type_id::create("seq_rb");
        seq_rb.reg_model = env.reg_model;
        seq_rb.start(env.agent.sequencer);

        // 3. Directed: Permissions (RO/WO)
        seq_perm = axi_permission_seq::type_id::create("seq_perm");
        seq_perm.reg_model = env.reg_model;
        seq_perm.start(env.agent.sequencer);

        // 4. Directed: Byte Strobes
        seq_strobe = axi_byte_strobe_seq::type_id::create("seq_strobe");
        seq_strobe.start(env.agent.sequencer);

        // 5. Directed: Mid-Flight Reset
        seq_reset = axi_mid_reset_seq::type_id::create("seq_reset");
        seq_reset.start(env.agent.sequencer);

        // 6. Timing Corner Case: AW before W
        seq_aw_w = axi_aw_before_w_seq::type_id::create("seq_aw_w");
        seq_aw_w.start(env.agent.sequencer);

        // 7. Timing Corner Case: W before AW
        seq_w_aw = axi_w_before_aw_seq::type_id::create("seq_w_aw");
        seq_w_aw.start(env.agent.sequencer);
        
        // 8. Timing Corner Case: Simultaneous Arrival
        seq_simult = axi_simultaneous_aw_w_seq::type_id::create("seq_simult");
        seq_simult.start(env.agent.sequencer);

        // 9. Protocol Stress: Heavy Backpressure
        seq_bp = axi_backpressure_seq::type_id::create("seq_bp");
        seq_bp.start(env.agent.sequencer);

        // 10. Constrained Random Sweep
        `uvm_info("REGR", "--- COMMENCING RANDOM SWEEP ---", UVM_LOW)
        seq_rand = axi_random_seq::type_id::create("seq_rand");
        seq_rand.num_transactions = 500; // Unleash the hounds to close the remaining crosses
        seq_rand.start(env.agent.sequencer);

        `uvm_info("REGR", "--- REGRESSION SUITE COMPLETE ---", UVM_LOW)
        phase.drop_objection(this, "Regression Complete");
    endtask
endclass

`endif 
