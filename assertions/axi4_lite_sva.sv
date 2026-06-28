`ifndef AXI4_LITE_SVA_SV
`define AXI4_LITE_SVA_SV

module axi4_lite_sva #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) (
    input logic                  aclk,
    input logic                  aresetn,

    // Write Address Channel
    input logic [ADDR_WIDTH-1:0] awaddr,
    input logic                  awvalid,
    input logic                  awready,

    // Write Data Channel
    input logic [DATA_WIDTH-1:0] wdata,
    input logic [3:0]            wstrb,
    input logic                  wvalid,
    input logic                  wready,

    // Write Response Channel
    input logic [1:0]            bresp,
    input logic                  bvalid,
    input logic                  bready,

    // Read Address Channel
    input logic [ADDR_WIDTH-1:0] araddr,
    input logic                  arvalid,
    input logic                  arready,

    // Read Data Channel
    input logic [DATA_WIDTH-1:0] rdata,
    input logic [1:0]            rresp,
    input logic                  rvalid,
    input logic                  rready
);

    // Global setup for all concurrent assertions in this module
    default clocking @(posedge aclk); endclocking
    default disable iff (!aresetn);

    // 1. WRITE ADDRESS CHANNEL (AW) RULES

    property p_awvalid_stable;
        awvalid && !awready |=> awvalid;
    endproperty
    a_awvalid_stable: assert property (p_awvalid_stable)
        else $error("AXI4-Lite Violation: AWVALID deasserted before AWREADY was received.");

    property p_awaddr_stable;
        awvalid && !awready |=> $stable(awaddr);
    endproperty
    a_awaddr_stable: assert property (p_awaddr_stable)
        else $error("AXI4-Lite Violation: AWADDR mutated while waiting for AWREADY.");

    // 2. WRITE DATA CHANNEL (W) RULES

    property p_wvalid_stable;
        wvalid && !wready |=> wvalid;
    endproperty
    a_wvalid_stable: assert property (p_wvalid_stable)
        else $error("AXI4-Lite Violation: WVALID deasserted before WREADY was received.");

    property p_wdata_stable;
        wvalid && !wready |=> $stable(wdata) && $stable(wstrb);
    endproperty
    a_wdata_stable: assert property (p_wdata_stable)
        else $error("AXI4-Lite Violation: WDATA or WSTRB mutated while waiting for WREADY.");

    // 3. WRITE RESPONSE CHANNEL (B) RULES

    property p_bvalid_stable;
        bvalid && !bready |=> bvalid;
    endproperty
    a_bvalid_stable: assert property (p_bvalid_stable)
        else $error("AXI4-Lite Violation: BVALID deasserted before BREADY was received.");

    property p_bresp_stable;
        bvalid && !bready |=> $stable(bresp);
    endproperty
    a_bresp_stable: assert property (p_bresp_stable)
        else $error("AXI4-Lite Violation: BRESP mutated while waiting for BREADY.");

    // 4. READ ADDRESS CHANNEL (AR) RULES

    property p_arvalid_stable;
        arvalid && !arready |=> arvalid;
    endproperty
    a_arvalid_stable: assert property (p_arvalid_stable)
        else $error("AXI4-Lite Violation: ARVALID deasserted before ARREADY was received.");

    property p_araddr_stable;
        arvalid && !arready |=> $stable(araddr);
    endproperty
    a_araddr_stable: assert property (p_araddr_stable)
        else $error("AXI4-Lite Violation: ARADDR mutated while waiting for ARREADY.");

    // 5. READ DATA CHANNEL (R) RULES

    property p_rvalid_stable;
        rvalid && !rready |=> rvalid;
    endproperty
    a_rvalid_stable: assert property (p_rvalid_stable)
        else $error("AXI4-Lite Violation: RVALID deasserted before RREADY was received.");

    property p_rdata_stable;
        rvalid && !rready |=> $stable(rdata) && $stable(rresp);
    endproperty
    a_rdata_stable: assert property (p_rdata_stable)
        else $error("AXI4-Lite Violation: RDATA or RRESP mutated while waiting for RREADY.");

    // 6. UNKNOWN STATE (X/Z) SANITY CHECKS
    
    // Handshake control pins must never float to 'X' or 'Z' during active reset
    a_no_x_awvalid: assert property (!$isunknown(awvalid)) 
        else $error("AXI4-Lite X-Prop: AWVALID went to X/Z.");
    a_no_x_wvalid:  assert property (!$isunknown(wvalid))  
        else $error("AXI4-Lite X-Prop: WVALID went to X/Z.");
    a_no_x_arvalid: assert property (!$isunknown(arvalid)) 
        else $error("AXI4-Lite X-Prop: ARVALID went to X/Z.");

endmodule

`endif 
