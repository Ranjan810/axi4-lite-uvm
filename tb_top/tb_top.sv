`timescale 1ns / 1ps

// Include UVM Macros and Package
import uvm_pkg::*;
import tb_pkg::*;

module tb_top;

    // Clock and Reset Generation

    logic aclk;
    logic aresetn;

    // 100MHz Clock (10ns period)
    initial begin
        aclk = 1'b0;
        forever #5 aclk = ~aclk;
    end

    // Reset Sequence
    initial begin
        aresetn = 1'b0;
        #50; // Hold reset for 50ns
        aresetn = 1'b1;
    end

    // Interface Instantiation

    axi4_lite_if #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32)
    ) axi_vif (
        .aclk(aclk),
        .aresetn(aresetn)
    );

    // Hardware-Facing Tie-Offs (Mocking the SoC side)

    logic [31:0] mock_hw_status_in;
    logic [31:0] mock_hw_data_out;
    logic [31:0] mock_hw_ctrl_out;
    logic [31:0] mock_hw_data_in;

    // Simulate some hardware status changing over time for the scoreboard to check
    initial begin
        mock_hw_status_in = 32'h0000_0000;
        mock_hw_data_out  = 32'hDEAD_BEEF;
        forever begin
            #200;
            mock_hw_status_in = mock_hw_status_in + 1; // Hardware status ticks up
        end
    end

    // DUT Instantiation (Design Under Test)

    axi_lite_slave_top #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32)
    ) dut (
        .aclk         (axi_vif.aclk),
        .aresetn      (axi_vif.aresetn),
        
        // Write Address Channel
        .awaddr       (axi_vif.awaddr),
        .awprot       (axi_vif.awprot),
        .awvalid      (axi_vif.awvalid),
        .awready      (axi_vif.awready),
        
        // Write Data Channel
        .wdata        (axi_vif.wdata),
        .wstrb        (axi_vif.wstrb),
        .wvalid       (axi_vif.wvalid),
        .wready       (axi_vif.wready),
        
        // Write Response Channel
        .bresp        (axi_vif.bresp),
        .bvalid       (axi_vif.bvalid),
        .bready       (axi_vif.bready),
        
        // Read Address Channel
        .araddr       (axi_vif.araddr),
        .arprot       (axi_vif.arprot),
        .arvalid      (axi_vif.arvalid),
        .arready      (axi_vif.arready),
        
        // Read Data Channel
        .rdata        (axi_vif.rdata),
        .rresp        (axi_vif.rresp),
        .rvalid       (axi_vif.rvalid),
        .rready       (axi_vif.rready),

        // SoC Hardware Boundaries
        .hw_status_in (mock_hw_status_in),
        .hw_data_out  (mock_hw_data_out),
        .hw_ctrl_out  (mock_hw_ctrl_out),
        .hw_data_in   (mock_hw_data_in)
    );

    // SVA Assertions Binding
    // Bind the protocol checker to the physical interface
    bind axi_lite_slave_top axi4_lite_sva sva_checker (
        .aclk    (aclk),
        .aresetn (aresetn),
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
        .araddr  (araddr),
        .arvalid (arvalid),
        .arready (arready),
        .rdata   (rdata),
        .rresp   (rresp),
        .rvalid  (rvalid),
        .rready  (rready)
    );

    // UVM Initialization

    initial begin
        // Pass the physical interface into the UVM configuration database
        // so the Driver and Monitor can fetch it in their build_phase().
        uvm_config_db#(virtual axi4_lite_if)::set(null, "*", "vif", axi_vif);
        
        // Let the run options determine the test
        run_test(); 
    end

    // Waveform Dumping

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_top);
        
    end

endmodule
