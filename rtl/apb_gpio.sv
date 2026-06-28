`timescale 1ns / 1ps

module apb_gpio #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int GPIO_WIDTH = 16
) (
    input  logic                  pclk,
    input  logic                  presetn,

    // APB Slave Interface
    /* verilator lint_off UNUSEDSIGNAL */
    input  logic [ADDR_WIDTH-1:0] paddr,
    /* verilator lint_on UNUSEDSIGNAL */
    input  logic                  psel,
    input  logic                  penable,
    input  logic                  pwrite,
    input  logic [DATA_WIDTH-1:0] pwdata,
    output logic [DATA_WIDTH-1:0] prdata,
    output logic                  pready,
    output logic                  pslverr,

    // Physical GPIO Pins
    input  logic [GPIO_WIDTH-1:0] gpio_in,
    output logic [GPIO_WIDTH-1:0] gpio_out,
    output logic [GPIO_WIDTH-1:0] gpio_dir
);

    logic [31:0] reg_dir;
    logic [31:0] reg_out;

    assign pready  = 1'b1; // Zero wait state peripheral
    assign pslverr = 1'b0; // No error generation in this simple GPIO

    assign gpio_dir = reg_dir[GPIO_WIDTH-1:0];
    assign gpio_out = reg_out[GPIO_WIDTH-1:0];

    // Write Logic
    always_ff @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            reg_dir <= '0;
            reg_out <= '0;
        end else if (psel && penable && pwrite) begin
            case (paddr[7:0])
                8'h00: reg_dir <= pwdata;
                8'h04: reg_out <= pwdata;
                default: ; // Do nothing
            endcase
        end
    end

    // Read Logic
    always_comb begin
        prdata = '0;
        if (psel && !pwrite) begin
            case (paddr[7:0])
                8'h00: prdata = reg_dir;
                8'h04: prdata = reg_out;
                8'h08: prdata = { {(32-GPIO_WIDTH){1'b0}}, gpio_in };
                default: prdata = '0;
            endcase
        end
    end

endmodule
