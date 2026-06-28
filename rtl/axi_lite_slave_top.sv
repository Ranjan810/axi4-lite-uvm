`timescale 1ns / 1ps

module axi_lite_slave_top #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) (
    input  logic                  aclk,
    input  logic                  aresetn,

    // AXI Write Address Channel (AW)

    input  logic [ADDR_WIDTH-1:0] awaddr,
    /* verilator lint_off UNUSEDSIGNAL */
    input  logic [2:0]            awprot,
    /* verilator lint_on UNUSEDSIGNAL */
    input  logic                  awvalid,
    output logic                  awready,

    // AXI Write Data Channel (W)

    input  logic [DATA_WIDTH-1:0] wdata,
    input  logic [3:0]            wstrb,
    input  logic                  wvalid,
    output logic                  wready,

    // AXI Write Response Channel (B)

    output logic [1:0]            bresp,
    output logic                  bvalid,
    input  logic                  bready,

    // AXI Read Address Channel (AR)

    input  logic [ADDR_WIDTH-1:0] araddr,
    /* verilator lint_off UNUSEDSIGNAL */
    input  logic [2:0]            arprot,
    /* verilator lint_on UNUSEDSIGNAL */
    input  logic                  arvalid,
    output logic                  arready,

    // AXI Read Data Channel (R)

    output logic [DATA_WIDTH-1:0] rdata,
    output logic [1:0]            rresp,
    output logic                  rvalid,
    input  logic                  rready,

    // Hardware-Facing Interface (SoC boundary)

    input  logic [31:0]           hw_status_in,
    input  logic [31:0]           hw_data_out,
    output logic [31:0]           hw_ctrl_out,
    output logic [31:0]           hw_data_in
);

    // Internal Interconnect Signals

    logic                  wr_en;
    logic [ADDR_WIDTH-1:0] wr_addr;
    logic [DATA_WIDTH-1:0] wr_data;
    logic [3:0]            wr_strb;
    logic                  wr_err;

    logic                  rd_en;
    logic [ADDR_WIDTH-1:0] rd_addr;
    logic [DATA_WIDTH-1:0] rd_data;
    logic                  rd_err;

    // Write FSM Instantiation

    axi_write_fsm #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_write_fsm (
        .clk     (aclk),
        .rst_n   (aresetn),
        .awaddr  (awaddr),
        .awvalid (awvalid),
        .awready (awready),
        .wdata   (wdata),
        .wstrb   (wstrb),
        .wvalid  (wvalid),
        .wready  (wready),
        .bresp   (bresp),
        .bvalid  (bvalid),
        .bready  (bready),
        .wr_en   (wr_en),
        .wr_addr (wr_addr),
        .wr_data (wr_data),
        .wr_strb (wr_strb),
        .wr_err  (wr_err)
    );

    // Read FSM Instantiation

    axi_read_fsm #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_read_fsm (
        .clk     (aclk),
        .rst_n   (aresetn),
        .araddr  (araddr),
        .arvalid (arvalid),
        .arready (arready),
        .rdata   (rdata),
        .rresp   (rresp),
        .rvalid  (rvalid),
        .rready  (rready),
        .rd_en   (rd_en),
        .rd_addr (rd_addr),
        .rd_data (rd_data),
        .rd_err  (rd_err)
    );

    // Register File Instantiation

    axi_reg_file #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_reg_file (
        .clk          (aclk),
        .rst_n        (aresetn),
        .wr_en        (wr_en),
        .wr_addr      (wr_addr),
        .wr_data      (wr_data),
        .wr_strb      (wr_strb),
        .wr_err       (wr_err),
        .rd_en        (rd_en),
        .rd_addr      (rd_addr),
        .rd_data      (rd_data),
        .rd_err       (rd_err),
        .hw_status_in (hw_status_in),
        .hw_data_out  (hw_data_out),
        .hw_ctrl_out  (hw_ctrl_out),
        .hw_data_in   (hw_data_in)
    );

endmodule
