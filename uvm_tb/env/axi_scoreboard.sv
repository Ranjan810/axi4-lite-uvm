`ifndef AXI_SCOREBOARD_SV
`define AXI_SCOREBOARD_SV

class axi_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(axi_scoreboard)

    uvm_analysis_imp #(axi_seq_item, axi_scoreboard) item_collected_export;
    
    // Added Virtual Interface to monitor Reset
    virtual axi4_lite_if vif;

    // Parameterized Memory Map Mirror
    localparam bit [7:0] ADDR_CTRL      = 8'h00;
    localparam bit [7:0] ADDR_STATUS    = 8'h04;
    localparam bit [7:0] ADDR_IRQ_EN    = 8'h08;
    localparam bit [7:0] ADDR_IRQ_STAT  = 8'h0C;
    localparam bit [7:0] ADDR_DATA_IN   = 8'h10;
    localparam bit [7:0] ADDR_VERSION   = 8'h14;
    localparam bit [7:0] ADDR_DATA_OUT  = 8'h18;
    localparam bit [7:0] ADDR_CFG_BASE  = 8'h1C;
    
    localparam int NUM_CONFIG_REGS = 25;
    localparam bit [7:0] ADDR_CFG_MAX   = ADDR_CFG_BASE + (NUM_CONFIG_REGS * 4) - 4;

    // Golden Behavioral Mirror Storage
    bit [31:0] mirror_ctrl;
    bit [31:0] mirror_irq_enable;
    bit [31:0] mirror_irq_status;
    bit [31:0] mirror_config [0:NUM_CONFIG_REGS-1];

    function new(string name = "axi_scoreboard", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        item_collected_export = new("item_collected_export", this);
        
        if (!uvm_config_db#(virtual axi4_lite_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("SCB_VIF_ERR", "Scoreboard failed to get virtual interface for reset monitoring")
        end
        
        reset_mirror();
    endfunction

    // Reset Awareness Task

    task run_phase(uvm_phase phase);
        forever begin
            @(negedge vif.aresetn);
            `uvm_info("SCB_RST", "Hardware Reset Detected. Wiping Scoreboard Mirror.", UVM_LOW)
            reset_mirror();
        end
    endtask

    function void reset_mirror();
        mirror_ctrl       = 32'h0;
        mirror_irq_enable = 32'h0;
        mirror_irq_status = 32'h0;
        foreach(mirror_config[i]) mirror_config[i] = 32'h0;
    endfunction

    function bit [31:0] apply_strobe(bit [31:0] current_val, bit [31:0] write_val, bit [3:0] strobe);
        bit [31:0] result;
        result[7:0]   = strobe[0] ? write_val[7:0]   : current_val[7:0];
        result[15:8]  = strobe[1] ? write_val[15:8]  : current_val[15:8];
        result[23:16] = strobe[2] ? write_val[23:16] : current_val[23:16];
        result[31:24] = strobe[3] ? write_val[31:24] : current_val[31:24];
        return result;
    endfunction

    // Golden Prediction & Checking

    virtual function void write(axi_seq_item item);
        bit [1:0]  expected_resp = 2'b00; 
        bit [31:0] expected_data = 32'h0;
        bit [7:0]  addr_offset   = item.addr[7:0];

        if (item.op == AXI_WRITE) begin
            // 1. Predict Access Violations
            if ((addr_offset > ADDR_CFG_MAX) || 
                (addr_offset == ADDR_STATUS) || 
                (addr_offset == ADDR_VERSION) || 
                (addr_offset == ADDR_DATA_OUT)) begin
                expected_resp = 2'b10;
            end else begin
                // 2. Execute Golden Model Writes
                case (addr_offset)
                    ADDR_CTRL:     mirror_ctrl = apply_strobe(mirror_ctrl, item.data, item.strb) & 32'h0000_0007;
                    ADDR_IRQ_EN:   mirror_irq_enable = apply_strobe(mirror_irq_enable, item.data, item.strb);
                    ADDR_IRQ_STAT: mirror_irq_status = mirror_irq_status & ~apply_strobe(32'h0, item.data, item.strb); // W1C
                    ADDR_DATA_IN:  ; // Absorbed by hardware
                    default: begin
                        if (addr_offset >= ADDR_CFG_BASE && addr_offset <= ADDR_CFG_MAX) begin
                            int idx = (addr_offset - ADDR_CFG_BASE) >> 2;
                            mirror_config[idx] = apply_strobe(mirror_config[idx], item.data, item.strb);
                        end
                    end
                endcase
            end

            // 3. Compare Response
            if (item.resp !== expected_resp) begin
                `uvm_error("SCB_FAIL", $sformatf("WRITE Resp Mismatch @%0h. Exp: %0h, Act: %0h", item.addr, expected_resp, item.resp))
            end else begin
                `uvm_info("SCB_PASS", $sformatf("WRITE predicted perfectly @%0h", item.addr), UVM_HIGH)
            end

        end else begin
            // 1. Predict Access Violations
            if ((addr_offset > ADDR_CFG_MAX) || (addr_offset == ADDR_DATA_IN)) begin
                expected_resp = 2'b10;
            end else begin
                // 2. Fetch Golden Data
                case (addr_offset)
                    ADDR_CTRL:     expected_data = mirror_ctrl;
                    ADDR_IRQ_EN:   expected_data = mirror_irq_enable;
                    ADDR_IRQ_STAT: expected_data = mirror_irq_status;
                    ADDR_VERSION:  expected_data = 32'h0001_0000;
                    default: begin
                        if (addr_offset >= ADDR_CFG_BASE && addr_offset <= ADDR_CFG_MAX) begin
                            expected_data = mirror_config[(addr_offset - ADDR_CFG_BASE) >> 2];
                        end
                    end
                endcase
            end

            // 3. Compare Response & Data
            if (item.resp !== expected_resp) begin
                `uvm_error("SCB_FAIL", $sformatf("READ Resp Mismatch @%0h. Exp: %0h, Act: %0h", item.addr, expected_resp, item.resp))
            end else if (expected_resp == 2'b00) begin
                // Skip precise data checks for hardware-driven asynchronous registers
                if (addr_offset == ADDR_STATUS || addr_offset == ADDR_DATA_OUT) begin
                    `uvm_info("SCB_PASS", $sformatf("READ OK @%0h. (HW-Driven Data: %0h). Data check skipped.", item.addr, item.data), UVM_HIGH)
                end else if (item.data !== expected_data) begin
                    `uvm_error("SCB_FAIL", $sformatf("READ Data Mismatch @%0h. Exp: %0h, Act: %0h", item.addr, expected_data, item.data))
                end else begin
                    `uvm_info("SCB_PASS", $sformatf("READ predicted perfectly @%0h Data: %0h", item.addr, item.data), UVM_HIGH)
                end
            end
        end
    endfunction

endclass : axi_scoreboard

`endif 
