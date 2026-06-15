`ifndef AXI4_LITE_IF_SV
`define AXI4_LITE_IF_SV

interface axi4_lite_if #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) (
    input logic aclk,
    input logic aresetn
);

    // ---------------------------------------------------------
    // Write Address Channel (AW)
    // ---------------------------------------------------------
    logic [ADDR_WIDTH-1:0] awaddr;
    logic [2:0]            awprot;
    logic                  awvalid;
    logic                  awready;

    // ---------------------------------------------------------
    // Write Data Channel (W)
    // ---------------------------------------------------------
    logic [DATA_WIDTH-1:0]   wdata;
    logic [(DATA_WIDTH/8)-1:0] wstrb;
    logic                    wvalid;
    logic                    wready;

    // ---------------------------------------------------------
    // Write Response Channel (B)
    // ---------------------------------------------------------
    logic [1:0] bresp;
    logic       bvalid;
    logic       bready;

    // ---------------------------------------------------------
    // Read Address Channel (AR)
    // ---------------------------------------------------------
    logic [ADDR_WIDTH-1:0] araddr;
    logic [2:0]            arprot;
    logic                  arvalid;
    logic                  arready;

    // ---------------------------------------------------------
    // Read Data Channel (R)
    // ---------------------------------------------------------
    logic [DATA_WIDTH-1:0] rdata;
    logic [1:0]            rresp;
    logic                  rvalid;
    logic                  rready;

    // ---------------------------------------------------------
    // Modports (Directionality Enforcers)
    // ---------------------------------------------------------
    modport slave (
        input  aclk, aresetn,
        input  awaddr, awprot, awvalid,
        output awready,
        input  wdata, wstrb, wvalid,
        output wready,
        output bresp, bvalid,
        input  bready,
        input  araddr, arprot, arvalid,
        output arready,
        output rdata, rresp, rvalid,
        input  rready
    );

    modport master (
        input  aclk, aresetn,
        output awaddr, awprot, awvalid,
        input  awready,
        output wdata, wstrb, wvalid,
        input  wready,
        input  bresp, bvalid,
        output bready,
        output araddr, arprot, arvalid,
        input  arready,
        input  rdata, rresp, rvalid,
        output rready
    );

endinterface : axi4_lite_if

`endif // AXI4_LITE_IF_SV

