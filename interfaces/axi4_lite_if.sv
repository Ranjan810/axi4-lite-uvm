`ifndef AXI4_LITE_IF_SV
`define AXI4_LITE_IF_SV

interface axi4_lite_if #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) (
    input logic aclk,
    input logic aresetn
);

    // AXI4-Lite Signal Declarations

    logic [ADDR_WIDTH-1:0] awaddr;
    logic [2:0]            awprot;
    logic                  awvalid;
    logic                  awready;

    logic [DATA_WIDTH-1:0]   wdata;
    logic [(DATA_WIDTH/8)-1:0] wstrb;
    logic                    wvalid;
    logic                    wready;

    logic [1:0]            bresp;
    logic                  bvalid;
    logic                  bready;

    logic [ADDR_WIDTH-1:0] araddr;
    logic [2:0]            arprot;
    logic                  arvalid;
    logic                  arready;

    logic [DATA_WIDTH-1:0] rdata;
    logic [1:0]            rresp;
    logic                  rvalid;
    logic                  rready;

    // UVM Driver Clocking Block

    clocking drv_cb @(posedge aclk);
        default input #1ns output #1ns;
        // Master outputs (driven by testbench)
        output awaddr, awprot, awvalid, wdata, wstrb, wvalid, bready, araddr, arprot, arvalid, rready;
        // Master inputs (sampled by testbench)
        input  awready, wready, bresp, bvalid, arready, rdata, rresp, rvalid;
    endclocking : drv_cb

    // UVM Monitor Clocking Block

    clocking mon_cb @(posedge aclk);
        default input #1ns output #1ns;
        // Monitor treats all protocol signals purely as inputs
        input awaddr, awprot, awvalid, awready;
        input wdata, wstrb, wvalid, wready;
        input bresp, bvalid, bready;
        input araddr, arprot, arvalid, arready;
        input rdata, rresp, rvalid, rready;
    endclocking : mon_cb

    // Modports for RTL Enforcements

    modport slave (
        input  aclk, aresetn,
        input  awaddr, awprot, awvalid, output awready,
        input  wdata, wstrb, wvalid,    output wready,
        output bresp, bvalid,           input  bready,
        input  araddr, arprot, arvalid, output arready,
        output rdata, rresp, rvalid,    input  rready
    );

    // Testbench modports link directly to the stable clocking blocks
    modport drv_mp (clocking drv_cb, input aclk, input aresetn);
    modport mon_mp (clocking mon_cb, input aclk, input aresetn);

endinterface : axi4_lite_if

`endif 
