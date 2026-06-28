`timescale 1ns / 1ps

module axi_write_fsm #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) (
    input  logic                  clk,
    input  logic                  rst_n,

    // AXI Write Address Channel
    input  logic [ADDR_WIDTH-1:0] awaddr,
    input  logic                  awvalid,
    output logic                  awready,

    // AXI Write Data Channel
    input  logic [DATA_WIDTH-1:0] wdata,
    input  logic [3:0]            wstrb,
    input  logic                  wvalid,
    output logic                  wready,

    // AXI Write Response Channel
    output logic [1:0]            bresp,
    output logic                  bvalid,
    input  logic                  bready,

    // Internal Register File Interface
    output logic                  wr_en,
    output logic [ADDR_WIDTH-1:0] wr_addr,
    output logic [DATA_WIDTH-1:0] wr_data,
    output logic [3:0]            wr_strb,
    input  logic                  wr_err
);

    typedef enum logic [1:0] {IDLE, EXECUTE, RESPONSE} state_t;
    state_t state, next_state;

    // Dedicated Channel Buffering Registers
    logic                  aw_buffered;
    logic                  w_buffered;
    logic [ADDR_WIDTH-1:0] awaddr_buf;
    logic [DATA_WIDTH-1:0] wdata_buf;
    logic [3:0]            wstrb_buf;

    // Ready signals are independent and open if buffers are free and we are in IDLE
    assign awready = !aw_buffered && (state == IDLE);
    assign wready  = !w_buffered  && (state == IDLE);

    // Buffering Logic

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            aw_buffered <= 1'b0;
            awaddr_buf  <= '0;
            w_buffered  <= 1'b0;
            wdata_buf   <= '0;
            wstrb_buf   <= '0;
        end else begin
            if (state == EXECUTE) begin
                // Clear buffers once we enter execution phase
                aw_buffered <= 1'b0;
                w_buffered  <= 1'b0;
            end else begin
                if (awvalid && awready) begin
                    aw_buffered <= 1'b1;
                    awaddr_buf  <= awaddr;
                end
                if (wvalid && wready) begin
                    w_buffered <= 1'b1;
                    wdata_buf  <= wdata;
                    wstrb_buf  <= wstrb;
                end
            end
        end
    end

    // State Machine

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else        state <= next_state;
    end

    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                // Proceed to execute only when BOTH components are captured
                if ((aw_buffered || (awvalid && awready)) && 
                    (w_buffered  || (wvalid && wready))) begin
                    next_state = EXECUTE;
                end
            end
            EXECUTE: begin
                next_state = RESPONSE;
            end
            RESPONSE: begin
                if (bready) next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // Registered Execution & Response Outputs

    assign wr_en   = (state == EXECUTE);
    // Address/Data is driven from buffers during execution
    assign wr_addr = awaddr_buf;
    assign wr_data = wdata_buf;
    assign wr_strb = wstrb_buf;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bvalid <= 1'b0;
            bresp  <= 2'b00;
        end else begin
            if (state == EXECUTE) begin
                bvalid <= 1'b1;
                bresp  <= wr_err ? 2'b10 : 2'b00; 
            end else if (state == RESPONSE && bready) begin
                bvalid <= 1'b0;
            end
        end
    end

    // Internal Assertions (Ignored by Synthesis)
    // Synthesis translate_off
    a_aw_no_overwrite: assert property (@(posedge clk) disable iff (!rst_n) 
        aw_buffered |=> !(awvalid && awready)) 
        else $error("Write FSM: AW buffer overwritten before execution!");

    a_w_no_overwrite: assert property (@(posedge clk) disable iff (!rst_n) 
        w_buffered |=> !(wvalid && wready)) 
        else $error("Write FSM: W buffer overwritten before execution!");
    // Synthesis translate_on

endmodule
