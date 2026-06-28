`ifndef AXI_AGENT_SV
`define AXI_AGENT_SV

class axi_agent extends uvm_agent;

    `uvm_component_utils(axi_agent)

    axi_driver    driver;
    axi_monitor   monitor;
    axi_sequencer sequencer;

    // Analysis port to expose the monitor's port to the wider environment
    uvm_analysis_port #(axi_seq_item) agent_ap;

    function new(string name = "axi_agent", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        agent_ap = new("agent_ap", this);
        monitor  = axi_monitor::type_id::create("monitor", this);
        
        // Only build the driver and sequencer if the agent is actively driving traffic
        if (get_is_active() == UVM_ACTIVE) begin
            driver    = axi_driver::type_id::create("driver", this);
            sequencer = axi_sequencer::type_id::create("sequencer", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Connect the monitor's analysis port to the agent's external analysis port
        monitor.item_collected_port.connect(agent_ap);
        
        // Connect the sequencer to the driver
        if (get_is_active() == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction

endclass : axi_agent

`endif 
