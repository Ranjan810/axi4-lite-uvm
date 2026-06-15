`timescale 1ns / 1ps

module axi_write_fsm #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) (
    input  logic                  clk,
    input  logic                  rst_n,

    // ---------------------------------------------------------
    // AXI Write Address Channel (AW)
    // ---------------------------------------------------------
    input  logic [ADDR_WIDTH-1:0] awaddr,
    input  logic                  awvalid,
    output logic                  awready,

    // ---------------------------------------------------------
    // AXI Write Data Channel (W)
    // ---------------------------------------------------------
    input  logic [DATA_WIDTH-1:0] wdata,
    input  logic [3:0]            wstrb,
    input  logic                  wvalid,
    output logic                  wready,

    // ---------------------------------------------------------
    // AXI Write Response Channel (B)
    // ---------------------------------------------------------
    output logic [1:0]            bresp,
    output logic                  bvalid,
    input  logic                  bready,

    // ---------------------------------------------------------
    // Interface to Register File
    // ---------------------------------------------------------
    output logic                  wr_en,
    output logic [ADDR_WIDTH-1:0] wr_addr,
    output logic [DATA_WIDTH-1:0] wr_data,
    output logic [3:0]            wr_strb,
    input  logic                  wr_err      // High if access violation occurred
);

    // ---------------------------------------------------------
    // Internal Latch State
    // ---------------------------------------------------------
    logic aw_received;
    logic w_received;
    
    logic [ADDR_WIDTH-1:0] awaddr_reg;
    logic [DATA_WIDTH-1:0] wdata_reg;
    logic [3:0]            wstrb_reg;

    // ---------------------------------------------------------
    // Write Address (AW) Channel Logic
    // ---------------------------------------------------------
    // Ready is asserted if we haven't latched an address yet, 
    // AND the response channel isn't blocked by a previous transaction.
    assign awready = ~aw_received && ~bvalid;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            aw_received <= 1'b0;
            awaddr_reg  <= '0;
        end else begin
            if (awvalid && awready) begin
                aw_received <= 1'b1;
                awaddr_reg  <= awaddr;
            end else if (wr_en) begin
                // Clear the latch once the register file accepts the transaction
                aw_received <= 1'b0;
            end
        end
    end

    // ---------------------------------------------------------
    // Write Data (W) Channel Logic
    // ---------------------------------------------------------
    // Ready is asserted if we haven't latched data yet,
    // AND the response channel isn't blocked.
    assign wready = ~w_received && ~bvalid;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_received <= 1'b0;
            wdata_reg  <= '0;
            wstrb_reg  <= '0;
        end else begin
            if (wvalid && wready) begin
                w_received <= 1'b1;
                wdata_reg  <= wdata;
                wstrb_reg  <= wstrb;
            end else if (wr_en) begin
                // Clear the latch once the register file accepts the transaction
                w_received <= 1'b0;
            end
        end
    end

    // ---------------------------------------------------------
    // Register File Interface
    // ---------------------------------------------------------
    // Fire the write enable ONLY when both AW and W have been successfully latched,
    // and we are not currently waiting for the master to accept a previous response.
    assign wr_en   = aw_received && w_received && ~bvalid;
    assign wr_addr = awaddr_reg;
    assign wr_data = wdata_reg;
    assign wr_strb = wstrb_reg;

    // ---------------------------------------------------------
    // Write Response (B) Channel Logic
    // ---------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bvalid <= 1'b0;
            bresp  <= 2'b00;
        end else begin
            if (wr_en) begin
                // Transaction completed at the register file. Assert response.
                bvalid <= 1'b1;
                // Generate SLVERR (2'b10) if access was illegal, otherwise OKAY (2'b00)
                bresp  <= wr_err ? 2'b10 : 2'b00;
            end else if (bvalid && bready) begin
                // Master accepted the response. Clear the valid signal.
                bvalid <= 1'b0;
            end
        end
    end

endmodule
