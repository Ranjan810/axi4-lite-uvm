`timescale 1ns / 1ps

module axi_reg_file #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 32
) (
    input  logic                  clk,
    input  logic                  rst_n,

    // ---------------------------------------------------------
    // Interface from AXI Write FSM
    // ---------------------------------------------------------
    input  logic                  wr_en,
    /* verilator lint_off UNUSEDSIGNAL */
    input  logic [ADDR_WIDTH-1:0] wr_addr,
    /* verilator lint_on UNUSEDSIGNAL */
    input  logic [DATA_WIDTH-1:0] wr_data,
    input  logic [3:0]            wr_strb,
    output logic                  wr_err,

    // ---------------------------------------------------------
    // Interface from AXI Read FSM
    // ---------------------------------------------------------
    input  logic                  rd_en,
    /* verilator lint_off UNUSEDSIGNAL */
    input  logic [ADDR_WIDTH-1:0] rd_addr,
    /* verilator lint_on UNUSEDSIGNAL */
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic                  rd_err,

    // ---------------------------------------------------------
    // Hardware-Facing Interface (SoC boundary)
    // ---------------------------------------------------------
    input  logic [31:0]           hw_status_in,
    input  logic [31:0]           hw_data_out,
    output logic [31:0]           hw_ctrl_out,
    output logic [31:0]           hw_data_in
);

    // ---------------------------------------------------------
    // Internal Register Storage
    // ---------------------------------------------------------
    logic [31:0] reg_ctrl;
    logic [31:0] reg_irq_enable;
    logic [31:0] reg_irq_status;
    
    // CONFIG space: 0x1C to 0x7C inclusive = 25 registers
    logic [31:0] reg_config [0:24];

    // Hardware Outputs
    assign hw_ctrl_out = reg_ctrl;

    // Clean index calculations for CONFIG registers
    logic [4:0] cfg_wr_idx;
    logic [4:0] cfg_rd_idx;
    assign cfg_wr_idx = wr_addr[6:2] - 5'h07;
    assign cfg_rd_idx = rd_addr[6:2] - 5'h07;

    // ---------------------------------------------------------
    // Helper Function: Apply Byte Strobes
    // ---------------------------------------------------------
    function automatic logic [31:0] apply_strobe(
        input logic [31:0] current_val,
        input logic [31:0] write_val,
        input logic [3:0]  strobe
    );
        logic [31:0] result;
        result[7:0]   = strobe[0] ? write_val[7:0]   : current_val[7:0];
        result[15:8]  = strobe[1] ? write_val[15:8]  : current_val[15:8];
        result[23:16] = strobe[2] ? write_val[23:16] : current_val[23:16];
        result[31:24] = strobe[3] ? write_val[31:24] : current_val[31:24];
        return result;
    endfunction

    // ---------------------------------------------------------
    // Write Error Logic (Access Violations)
    // ---------------------------------------------------------
    always_comb begin
        wr_err = 1'b0;
        if (wr_en) begin
            if (wr_addr[7:0] == 8'h04 || // STATUS
                wr_addr[7:0] == 8'h14 || // VERSION
                wr_addr[7:0] == 8'h18 || // DATA_OUT
                wr_addr[7:0] >  8'h7C)   // Out of bounds
            begin
                wr_err = 1'b1;
            end
        end
    end

    // ---------------------------------------------------------
    // Write Data Logic
    // ---------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_ctrl       <= 32'h0;
            reg_irq_enable <= 32'h0;
            reg_irq_status <= 32'h0;
            hw_data_in     <= 32'h0;
            for (int i = 0; i < 25; i++) begin
                reg_config[i] <= 32'h0;
            end
        end else begin
            if (wr_en && !wr_err) begin
                case (wr_addr[7:0])
                    8'h00: begin
                        reg_ctrl <= apply_strobe(reg_ctrl, wr_data, wr_strb) & 32'h00FF_FFFF;
                    end
                    8'h08: begin
                        reg_irq_enable <= apply_strobe(reg_irq_enable, wr_data, wr_strb);
                    end
                    8'h0C: begin
                        logic [31:0] w1c_mask = apply_strobe(32'h0, wr_data, wr_strb);
                        reg_irq_status <= reg_irq_status & ~w1c_mask;
                    end
                    8'h10: begin
                        hw_data_in <= apply_strobe(hw_data_in, wr_data, wr_strb);
                    end
                    default: begin
                        if (wr_addr[7:0] >= 8'h1C && wr_addr[7:0] <= 8'h7C) begin
                            reg_config[cfg_wr_idx] <= apply_strobe(reg_config[cfg_wr_idx], wr_data, wr_strb);
                        end
                    end
                endcase
            end
        end
    end

    // ---------------------------------------------------------
    // Read Error & Data Logic
    // ---------------------------------------------------------
    always_comb begin
        rd_err  = 1'b0;
        rd_data = 32'h0;

        if (rd_en) begin
            case (rd_addr[7:0])
                8'h00: rd_data = reg_ctrl;
                8'h04: rd_data = hw_status_in;      // STATUS (RO)
                8'h08: rd_data = reg_irq_enable;
                8'h0C: rd_data = reg_irq_status;
                8'h10: rd_err  = 1'b1;              // DATA_IN (WO) - Read Violation
                8'h14: rd_data = 32'h0001_0000;     // VERSION (RO) - Fixed ID
                8'h18: rd_data = hw_data_out;       // DATA_OUT (RO)
                default: begin
                    if (rd_addr[7:0] >= 8'h1C && rd_addr[7:0] <= 8'h7C) begin
                        rd_data = reg_config[cfg_rd_idx];
                    end else begin
                        rd_err = 1'b1;              // Out of bounds
                    end
                end
            endcase
        end
    end

endmodule
