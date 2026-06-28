`ifndef APB_IF_SV
`define APB_IF_SV

interface apb_if #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) (
    input logic pclk,
    input logic presetn
);

    logic [ADDR_WIDTH-1:0] paddr;
    logic                  psel;
    logic                  penable;
    logic                  pwrite;
    logic [DATA_WIDTH-1:0] pwdata;
    logic [DATA_WIDTH-1:0] prdata;
    logic                  pready;
    logic                  pslverr;

    modport master (
        input  pclk, presetn,
        output paddr, psel, penable, pwrite, pwdata,
        input  prdata, pready, pslverr
    );

    modport slave (
        input  pclk, presetn,
        input  paddr, psel, penable, pwrite, pwdata,
        output prdata, pready, pslverr
    );

endinterface : apb_if

`endif 
