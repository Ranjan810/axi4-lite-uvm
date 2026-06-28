`timescale 1ns / 1ps

module axi_read_fsm #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int READ_LATENCY = 1
) (
    input  logic                  clk,
    input  logic                  rst_n,

    // AXI Read Address Channel
    input  logic [ADDR_WIDTH-1:0] araddr,
    input  logic                  arvalid,
    output logic                  arready,

    // AXI Read Data Channel
    output logic [DATA_WIDTH-1:0] rdata,
    output logic [1:0]            rresp,
    output logic                  rvalid,
    input  logic                  rready,

    // Interface to Register File
    output logic                  rd_en,
    output logic [ADDR_WIDTH-1:0] rd_addr,
    input  logic [DATA_WIDTH-1:0] rd_data,
    input  logic                  rd_err
);

    typedef enum logic [1:0] {IDLE, READ_WAIT, RVALID_HOLD} state_t;
    state_t state, next_state;
    
    logic [7:0] latency_cnt;
    
    // Internal holding registers
    logic [ADDR_WIDTH-1:0] araddr_buf;
    logic [DATA_WIDTH-1:0] rdata_buf;
    logic [1:0]            rresp_buf;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else        state <= next_state;
    end

    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (arvalid) next_state = (READ_LATENCY > 0) ? READ_WAIT : RVALID_HOLD;
            end
            READ_WAIT: begin
                if (latency_cnt == READ_LATENCY - 1) next_state = RVALID_HOLD;
            end
            RVALID_HOLD: begin
                if (rready) next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    assign arready = (state == IDLE);

    // Buffer the address to protect against master mutations post-handshake
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            araddr_buf <= '0;
        end else if (arvalid && arready) begin
            araddr_buf <= araddr;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            latency_cnt <= 8'h0;
        end else begin
            if (state == IDLE && arvalid) latency_cnt <= 8'h0;
            else if (state == READ_WAIT)  latency_cnt <= latency_cnt + 1;
        end
    end

    assign rd_en   = (state == IDLE && next_state == RVALID_HOLD) || 
                     (state == READ_WAIT && next_state == RVALID_HOLD);
    assign rd_addr = araddr_buf; // Drive from buffer

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rdata_buf <= '0;
            rresp_buf <= 2'b00;
        end else if (rd_en) begin
            rdata_buf <= rd_data;
            rresp_buf <= rd_err ? 2'b10 : 2'b00;
        end
    end

    assign rvalid = (state == RVALID_HOLD);
    assign rdata  = rdata_buf;
    assign rresp  = rresp_buf;

endmodule
