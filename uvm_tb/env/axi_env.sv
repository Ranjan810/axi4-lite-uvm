`ifndef AXI_ENV_SV
`define AXI_ENV_SV

class axi_env extends uvm_env;

    `uvm_component_utils(axi_env)

    // Component Handles

    axi_agent       agent;
    axi_scoreboard  scoreboard;
    axi_coverage    coverage;
    
    // RAL Components
    axi_reg_block   reg_model;
    axi_reg_adapter reg_adapter;
    uvm_reg_predictor #(axi_seq_item) predictor;

    // Constructor

    function new(string name = "axi_env", uvm_component parent);
        super.new(name, parent);
    endfunction

    // Build Phase

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Core Agent and Checkers
        agent      = axi_agent::type_id::create("agent", this);
        scoreboard = axi_scoreboard::type_id::create("scoreboard", this);
        coverage   = axi_coverage::type_id::create("coverage", this);
        
        // RAL Components
        reg_model   = axi_reg_block::type_id::create("reg_model");
        reg_model.build(); // Build the register map
        
        reg_adapter = axi_reg_adapter::type_id::create("reg_adapter", this);
        predictor   = uvm_reg_predictor#(axi_seq_item)::type_id::create("predictor", this);
    endfunction

    // Connect Phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Wire the Agent's analysis port to the Checkers
        agent.agent_ap.connect(scoreboard.item_collected_export);
        agent.agent_ap.connect(coverage.analysis_export);
        
        // Connect RAL to the Sequencer (for front-door active driving)
        if (agent.get_is_active() == UVM_ACTIVE) begin
            reg_model.default_map.set_sequencer(agent.sequencer, reg_adapter);
            reg_model.default_map.set_auto_predict(0); // We will use the explicit predictor
        end
        
        // Connect the Monitor to the RAL Predictor (for passive mirror updates)
        predictor.map     = reg_model.default_map;
        predictor.adapter = reg_adapter;
        agent.agent_ap.connect(predictor.bus_in);
    endfunction

endclass : axi_env

`endif 
