`ifndef AXI_DRIVER_SV
`define AXI_DRIVER_SV

class axi_driver extends uvm_driver #(axi_seq_item);

    `uvm_component_utils(axi_driver)

    virtual axi4_lite_if vif;

    function new(string name = "axi_driver", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi4_lite_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("DRV_VIF_ERR", "Driver failed to get virtual interface")
        end
    endfunction

    task run_phase(uvm_phase phase);
        reset_bus();
        
        forever begin
            seq_item_port.get_next_item(req);
            
            // CRITICAL FIX: Align to the clock edge before driving 0-delay items!
            @(vif.drv_cb); 
            
            if (req.random_reset) begin
                reset_bus();
            end else begin
                repeat(req.idle_cycles) @(vif.drv_cb);
                drive_item(req);
            end
            
            seq_item_port.item_done();
        end
    endtask

    // Safe Reset Execution 

    task reset_bus();
        vif.drv_cb.awvalid <= 1'b0;
        vif.drv_cb.awaddr  <= '0;
        vif.drv_cb.awprot  <= '0;
        
        vif.drv_cb.wvalid  <= 1'b0;
        vif.drv_cb.wdata   <= '0;
        vif.drv_cb.wstrb   <= '0;
        
        vif.drv_cb.bready  <= 1'b0;
        
        vif.drv_cb.arvalid <= 1'b0;
        vif.drv_cb.araddr  <= '0;
        vif.drv_cb.arprot  <= '0;
        vif.drv_cb.rready  <= 1'b0;
        
        if (vif.aresetn === 1'b0) begin
            wait(vif.aresetn === 1'b1);
        end
    endtask

    // Independent Channel Driving Logic

    task drive_item(axi_seq_item item);
        
        if (item.op == AXI_WRITE) begin
            fork
                begin
                    repeat(item.aw_delay) @(vif.drv_cb);
                    vif.drv_cb.awaddr  <= item.addr;
                    vif.drv_cb.awvalid <= 1'b1;
                    
                    do @(vif.drv_cb);
                    while (vif.drv_cb.awready !== 1'b1);
                    
                    vif.drv_cb.awvalid <= 1'b0;
                end
                
                begin
                    repeat(item.w_delay) @(vif.drv_cb);
                    vif.drv_cb.wdata  <= item.data;
                    vif.drv_cb.wstrb  <= item.strb;
                    vif.drv_cb.wvalid <= 1'b1;
                    
                    do @(vif.drv_cb);
                    while (vif.drv_cb.wready !== 1'b1);
                    
                    vif.drv_cb.wvalid <= 1'b0;
                end
            join

            repeat(item.bready_delay) @(vif.drv_cb);
            vif.drv_cb.bready <= 1'b1;
            
            do @(vif.drv_cb);
            while (vif.drv_cb.bvalid !== 1'b1);
            
            item.resp = vif.drv_cb.bresp; 
            vif.drv_cb.bready <= 1'b0;

        end else begin
            repeat(item.ar_delay) @(vif.drv_cb);
            vif.drv_cb.araddr  <= item.addr;
            vif.drv_cb.arvalid <= 1'b1;
            
            do @(vif.drv_cb);
            while (vif.drv_cb.arready !== 1'b1);
            vif.drv_cb.arvalid <= 1'b0;

            repeat(item.rready_delay) @(vif.drv_cb);
            vif.drv_cb.rready <= 1'b1;
            
            do @(vif.drv_cb);
            while (vif.drv_cb.rvalid !== 1'b1);
            
            item.data = vif.drv_cb.rdata;
            item.resp = vif.drv_cb.rresp;
            
            vif.drv_cb.rready <= 1'b0;
        end
        
    endtask

endclass : axi_driver

`endif 
