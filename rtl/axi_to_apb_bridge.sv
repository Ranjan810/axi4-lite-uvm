`timescale 1ns / 1ps

module axi_to_apb_bridge #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) (
    input  logic                  clk,
    input  logic                  rst_n,

    // AXI4-Lite Slave Interface
    input  logic [ADDR_WIDTH-1:0] awaddr,
    input  logic                  awvalid,
    output logic                  awready,
    input  logic [DATA_WIDTH-1:0] wdata,
    /* verilator lint_off UNUSEDSIGNAL */
    input  logic [3:0]            wstrb,
    /* verilator lint_on UNUSEDSIGNAL */
    input  logic                  wvalid,
    output logic                  wready,
    output logic [1:0]            bresp,
    output logic                  bvalid,
    input  logic                  bready,
    input  logic [ADDR_WIDTH-1:0] araddr,
    input  logic                  arvalid,
    output logic                  arready,
    output logic [DATA_WIDTH-1:0] rdata,
    output logic [1:0]            rresp,
    output logic                  rvalid,
    input  logic                  rready,

    // APB Master Interface
    output logic [ADDR_WIDTH-1:0] paddr,
    output logic                  psel,
    output logic                  penable,
    output logic                  pwrite,
    output logic [DATA_WIDTH-1:0] pwdata,
    input  logic [DATA_WIDTH-1:0] prdata,
    input  logic                  pready,
    input  logic                  pslverr
);

    typedef enum logic [1:0] {IDLE, SETUP, ACCESS} state_t;
    state_t state, next_state;

    // We only process one transaction at a time. Read has priority in this simple bridge.
    logic active_read;
    logic active_write;

    assign active_read  = arvalid;
    assign active_write = awvalid && wvalid && !arvalid; // Wait for both AW and W

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else        state <= next_state;
    end

    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (active_read || active_write) next_state = SETUP;
            end
            SETUP: begin
                next_state = ACCESS;
            end
            ACCESS: begin
                if (pready) next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // APB Control Signals
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            psel    <= 1'b0;
            penable <= 1'b0;
            pwrite  <= 1'b0;
            paddr   <= '0;
            pwdata  <= '0;
        end else begin
            if (state == IDLE && (active_read || active_write)) begin
                psel   <= 1'b1;
                pwrite <= active_write;
                paddr  <= active_read ? araddr : awaddr;
                pwdata <= wdata;
            end else if (state == SETUP) begin
                penable <= 1'b1;
            end else if (state == ACCESS && pready) begin
                psel    <= 1'b0;
                penable <= 1'b0;
            end
        end
    end

    // AXI Handshakes & Responses
    assign arready = (state == ACCESS && pready && !pwrite);
    assign awready = (state == ACCESS && pready && pwrite);
    assign wready  = awready;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rvalid <= 1'b0;
            bvalid <= 1'b0;
        end else begin
            // Read valid
            if (state == ACCESS && pready && !pwrite) rvalid <= 1'b1;
            else if (rvalid && rready) rvalid <= 1'b0;

            // Write valid
            if (state == ACCESS && pready && pwrite) bvalid <= 1'b1;
            else if (bvalid && bready) bvalid <= 1'b0;
        end
    end

    // Data and Response routing
    assign rdata = prdata;
    assign rresp = pslverr ? 2'b10 : 2'b00;
    assign bresp = pslverr ? 2'b10 : 2'b00;

endmodule
