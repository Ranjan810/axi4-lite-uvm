`timescale 1ns / 1ps

module axi_reg_file #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 32,
    parameter int NUM_CONFIG_REGS = 25
) (
    input  logic                  clk,
    input  logic                  rst_n,

    // AXI Write FSM Interface
    input  logic                  wr_en,
    /* verilator lint_off UNUSEDSIGNAL */
    input  logic [ADDR_WIDTH-1:0] wr_addr,
    /* verilator lint_on UNUSEDSIGNAL */
    input  logic [DATA_WIDTH-1:0] wr_data,
    input  logic [3:0]            wr_strb,
    output logic                  wr_err,

    // AXI Read FSM Interface
    input  logic                  rd_en,
    /* verilator lint_off UNUSEDSIGNAL */
    input  logic [ADDR_WIDTH-1:0] rd_addr,
    /* verilator lint_on UNUSEDSIGNAL */
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic                  rd_err,

    // Hardware-Facing Interface (SoC boundary)
    input  logic [31:0]           hw_status_in,
    input  logic [31:0]           hw_data_out,
    output logic [31:0]           hw_ctrl_out,
    output logic [31:0]           hw_data_in
);

    // Register Memory Map Definition

    localparam logic [7:0] ADDR_CTRL      = 8'h00;
    localparam logic [7:0] ADDR_STATUS    = 8'h04;
    localparam logic [7:0] ADDR_IRQ_EN    = 8'h08;
    localparam logic [7:0] ADDR_IRQ_STAT  = 8'h0C;
    localparam logic [7:0] ADDR_DATA_IN   = 8'h10;
    localparam logic [7:0] ADDR_VERSION   = 8'h14;
    localparam logic [7:0] ADDR_DATA_OUT  = 8'h18;
    localparam logic [7:0] ADDR_CFG_BASE  = 8'h1C;
    localparam logic [7:0] ADDR_CFG_MAX   = ADDR_CFG_BASE + (NUM_CONFIG_REGS * 4) - 4;

    // Internal Register Storage

    logic [31:0] reg_ctrl;
    logic [31:0] reg_irq_enable;
    logic [31:0] reg_irq_status;
    logic [31:0] reg_config [0:NUM_CONFIG_REGS-1];

    assign hw_ctrl_out = reg_ctrl;

    // Address Decoding (Industrial Style)

    logic wr_sel_ctrl, wr_sel_irq_en, wr_sel_irq_stat, wr_sel_data_in, wr_sel_config;
    logic wr_is_ro, wr_is_oob;
    
    assign wr_sel_ctrl     = (wr_addr[7:0] == ADDR_CTRL);
    assign wr_sel_irq_en   = (wr_addr[7:0] == ADDR_IRQ_EN);
    assign wr_sel_irq_stat = (wr_addr[7:0] == ADDR_IRQ_STAT);
    assign wr_sel_data_in  = (wr_addr[7:0] == ADDR_DATA_IN);
    assign wr_sel_config   = (wr_addr[7:0] >= ADDR_CFG_BASE && wr_addr[7:0] <= ADDR_CFG_MAX);
    
    assign wr_is_ro        = (wr_addr[7:0] == ADDR_STATUS) || (wr_addr[7:0] == ADDR_VERSION) || (wr_addr[7:0] == ADDR_DATA_OUT);
    assign wr_is_oob       = (wr_addr[7:0] > ADDR_CFG_MAX);
    assign wr_err          = wr_en && (wr_is_ro || wr_is_oob);

    logic rd_sel_ctrl, rd_sel_status, rd_sel_irq_en, rd_sel_irq_stat, rd_sel_version, rd_sel_data_out, rd_sel_config;
    logic rd_is_wo, rd_is_oob;

    assign rd_sel_ctrl     = (rd_addr[7:0] == ADDR_CTRL);
    assign rd_sel_status   = (rd_addr[7:0] == ADDR_STATUS);
    assign rd_sel_irq_en   = (rd_addr[7:0] == ADDR_IRQ_EN);
    assign rd_sel_irq_stat = (rd_addr[7:0] == ADDR_IRQ_STAT);
    assign rd_sel_version  = (rd_addr[7:0] == ADDR_VERSION);
    assign rd_sel_data_out = (rd_addr[7:0] == ADDR_DATA_OUT);
    assign rd_sel_config   = (rd_addr[7:0] >= ADDR_CFG_BASE && rd_addr[7:0] <= ADDR_CFG_MAX);

    assign rd_is_wo        = (rd_addr[7:0] == ADDR_DATA_IN);
    assign rd_is_oob       = (rd_addr[7:0] > ADDR_CFG_MAX);
    assign rd_err          = rd_en && (rd_is_wo || rd_is_oob);

    // Clean index calculations for CONFIG registers
    logic [31:0] cfg_wr_idx, cfg_rd_idx;
    assign cfg_wr_idx = (wr_addr[7:0] - ADDR_CFG_BASE) >> 2;
    assign cfg_rd_idx = (rd_addr[7:0] - ADDR_CFG_BASE) >> 2;

    // Helper Function: Apply Byte Strobes

    function automatic logic [31:0] apply_strobe(logic [31:0] current_val, logic [31:0] write_val, logic [3:0] strobe);
        logic [31:0] result;
        result[7:0]   = strobe[0] ? write_val[7:0]   : current_val[7:0];
        result[15:8]  = strobe[1] ? write_val[15:8]  : current_val[15:8];
        result[23:16] = strobe[2] ? write_val[23:16] : current_val[23:16];
        result[31:24] = strobe[3] ? write_val[31:24] : current_val[31:24];
        return result;
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_ctrl       <= 32'h0;
            reg_irq_enable <= 32'h0;
            reg_irq_status <= 32'h0;
            hw_data_in     <= 32'h0;
            for (int i = 0; i < NUM_CONFIG_REGS; i++) reg_config[i] <= 32'h0;
        end else begin
            if (wr_en && !wr_err) begin
                if (wr_sel_ctrl)     
                    reg_ctrl <= apply_strobe(reg_ctrl, wr_data, wr_strb) & 32'h0000_0007;
                if (wr_sel_irq_en)   
                    reg_irq_enable <= apply_strobe(reg_irq_enable, wr_data, wr_strb);
                if (wr_sel_irq_stat) 
                    reg_irq_status <= reg_irq_status & ~apply_strobe(32'h0, wr_data, wr_strb);
                if (wr_sel_data_in)  
                    hw_data_in <= apply_strobe(hw_data_in, wr_data, wr_strb);
                if (wr_sel_config)   
                    reg_config[cfg_wr_idx] <= apply_strobe(reg_config[cfg_wr_idx], wr_data, wr_strb);
            end
        end
    end

    always_comb begin
        rd_data = 32'h0;
        if (rd_en && !rd_err) begin
            if (rd_sel_ctrl)     rd_data = reg_ctrl;
            if (rd_sel_status)   rd_data = hw_status_in;
            if (rd_sel_irq_en)   rd_data = reg_irq_enable;
            if (rd_sel_irq_stat) rd_data = reg_irq_status;
            if (rd_sel_version)  rd_data = 32'h0001_0000;
            if (rd_sel_data_out) rd_data = hw_data_out;
            if (rd_sel_config)   rd_data = reg_config[cfg_rd_idx];
        end
    end

endmodule
