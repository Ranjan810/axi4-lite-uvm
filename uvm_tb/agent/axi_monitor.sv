`ifndef AXI_MONITOR_SV
`define AXI_MONITOR_SV

class axi_monitor extends uvm_monitor;

    `uvm_component_utils(axi_monitor)

    virtual axi4_lite_if vif;
    uvm_analysis_port #(axi_seq_item) item_collected_port;

    function new(string name = "axi_monitor", uvm_component parent);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi4_lite_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("MON_VIF_ERR", "Monitor failed to get virtual interface")
        end
    endfunction

    task run_phase(uvm_phase phase);
        wait(vif.aresetn === 1'b1);
        fork
            collect_writes();
            collect_reads();
        join_none
    endtask

    // Write Channel Monitor with Timing Metrics

    task collect_writes();
        forever begin
            axi_seq_item wr_item = axi_seq_item::type_id::create("wr_item");
            int aw_arrival_time, w_arrival_time;
            int response_latency = 0;

            wr_item.op = AXI_WRITE;

            // Wait for both AW and W handshakes concurrently
            fork
                begin // AW Handshake
                    do @(vif.mon_cb);
                    while (!(vif.mon_cb.awvalid && vif.mon_cb.awready));
                    wr_item.addr = vif.mon_cb.awaddr;
                    aw_arrival_time = $time;
                end
                
                begin // W Handshake
                    do @(vif.mon_cb);
                    while (!(vif.mon_cb.wvalid && vif.mon_cb.wready));
                    wr_item.data = vif.mon_cb.wdata;
                    wr_item.strb = vif.mon_cb.wstrb;
                    w_arrival_time = $time;
                end
            join

            // Determine arrival ordering
            if (aw_arrival_time < w_arrival_time) begin
                `uvm_info("MON_ORDER", "Write Tracking: AW arrived before W", UVM_HIGH)
            end else if (w_arrival_time < aw_arrival_time) begin
                `uvm_info("MON_ORDER", "Write Tracking: W arrived before AW", UVM_HIGH)
            end else begin
                `uvm_info("MON_ORDER", "Write Tracking: AW and W arrived simultaneously", UVM_HIGH)
            end

            // Measure response stall cycles
            while (!(vif.mon_cb.bvalid && vif.mon_cb.bready)) begin
                @(vif.mon_cb);
                if (vif.mon_cb.bvalid && !vif.mon_cb.bready) response_latency++;
            end
            
            wr_item.resp = vif.mon_cb.bresp;

            if (response_latency > 0) begin
                `uvm_info("MON_STALL", $sformatf("Master stalled Write Response (B channel) for %0d cycles", response_latency), UVM_HIGH)
            end

            item_collected_port.write(wr_item);
        end
    endtask

    // Read Channel Monitor with Timing Metrics

    task collect_reads();
        forever begin
            axi_seq_item rd_item = axi_seq_item::type_id::create("rd_item");
            int read_latency = 0;
            int response_latency = 0;

            rd_item.op = AXI_READ;

            // Wait for AR Handshake
            do @(vif.mon_cb);
            while (!(vif.mon_cb.arvalid && vif.mon_cb.arready));
            rd_item.addr = vif.mon_cb.araddr;

            // Measure Slave Read Latency
            while (!vif.mon_cb.rvalid) begin
                @(vif.mon_cb);
                read_latency++;
            end

            // Measure Master Response Stall (Back-pressure)
            while (!(vif.mon_cb.rvalid && vif.mon_cb.rready)) begin
                @(vif.mon_cb);
                if (vif.mon_cb.rvalid && !vif.mon_cb.rready) response_latency++;
            end
            
            rd_item.data = vif.mon_cb.rdata;
            rd_item.resp = vif.mon_cb.rresp;

            `uvm_info("MON_LATENCY", $sformatf("Read @%0h | Slave Latency: %0d | Master Stall: %0d", rd_item.addr, read_latency, response_latency), UVM_HIGH)

            item_collected_port.write(rd_item);
        end
    endtask

endclass : axi_monitor

`endif 
