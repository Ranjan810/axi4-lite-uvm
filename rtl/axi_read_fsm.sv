`timescale 1ns / 1ps

module axi_read_fsm #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) (
    input  logic                  clk,
    input  logic                  rst_n,

    // ---------------------------------------------------------
    // AXI Read Address Channel (AR)
    // ---------------------------------------------------------
    input  logic [ADDR_WIDTH-1:0] araddr,
    input  logic                  arvalid,
    output logic                  arready,

    // ---------------------------------------------------------
    // AXI Read Data Channel (R)
    // ---------------------------------------------------------
    output logic [DATA_WIDTH-1:0] rdata,
    output logic [1:0]            rresp,
    output logic                  rvalid,
    input  logic                  rready,

    // ---------------------------------------------------------
    // Interface to Register File
    // ---------------------------------------------------------
    output logic                  rd_en,
    output logic [ADDR_WIDTH-1:0] rd_addr,
    input  logic [DATA_WIDTH-1:0] rd_data,
    input  logic                  rd_err      // High if access violation occurred
);

    // Internal registers for the R channel
    logic [DATA_WIDTH-1:0] rdata_reg;
    logic [1:0]            rresp_reg;
    logic                  rvalid_reg;

    // ---------------------------------------------------------
    // Read Address (AR) Channel Logic
    // ---------------------------------------------------------
    // We can accept a new read address only if the R channel is idle.
    // If rvalid_reg is high, we are waiting for the master to assert rready,
    // so we must back-pressure the AR channel to avoid overwriting data.
    assign arready = ~rvalid_reg;

    // ---------------------------------------------------------
    // Register File Interface
    // ---------------------------------------------------------
    // The register file performs a combinational read based on rd_addr.
    // We drive rd_addr directly from araddr during the handshake cycle.
    assign rd_en   = arvalid && arready;
    assign rd_addr = araddr;

    // ---------------------------------------------------------
    // Read Data (R) Channel Logic
    // ---------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rvalid_reg <= 1'b0;
            rdata_reg  <= '0;
            rresp_reg  <= 2'b00;
        end else begin
            if (arvalid && arready) begin
                // AR handshake completed. Latch the combinational output 
                // from the register file into the R channel.
                rvalid_reg <= 1'b1;
                rdata_reg  <= rd_data;
                // Generate SLVERR (2'b10) if access was illegal, otherwise OKAY (2'b00)
                rresp_reg  <= rd_err ? 2'b10 : 2'b00;
            end else if (rvalid_reg && rready) begin
                // Master has accepted the read data. Clear the valid signal.
                rvalid_reg <= 1'b0;
            end
        end
    end

    // Drive the physical R channel outputs from the internal registers
    assign rvalid = rvalid_reg;
    assign rdata  = rdata_reg;
    assign rresp  = rresp_reg;

endmodule
