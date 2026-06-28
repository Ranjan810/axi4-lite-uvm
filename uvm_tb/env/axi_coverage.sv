`ifndef AXI_COVERAGE_SV
`define AXI_COVERAGE_SV

typedef enum {REG_RW, REG_RO, REG_WO, REG_W1C, REG_UNKNOWN} reg_type_e;

class axi_coverage extends uvm_subscriber #(axi_seq_item);

    `uvm_component_utils(axi_coverage)
    axi_seq_item tr;
    reg_type_e    reg_type;

    covergroup cg_axi_trans;
        option.per_instance = 1;

        // 1. Operation Type
        cp_op: coverpoint tr.op {
            bins read  = {AXI_READ};
            bins write = {AXI_WRITE};
        }

        // 2. Address Map (Includes invalid space to prove SLVERR generation)
        cp_addr: coverpoint tr.addr[7:0] {
            bins ctrl       = {8'h00};
            bins status     = {8'h04};
            bins irq_en     = {8'h08};
            bins irq_stat   = {8'h0C};
            bins data_in    = {8'h10};
            bins version    = {8'h14};
            bins data_out   = {8'h18};
            bins config_reg[] = {[8'h1C : 8'h7C]} with (item % 4 == 0);
            bins invalid    = {[8'h80 : 8'hFF]}; 
        }

        // 3. Response Codes
        cp_resp: coverpoint tr.resp {
            bins okay   = {2'b00};
            bins slverr = {2'b10};
        }

        // 4. Byte Strobes
        cp_strb: coverpoint tr.strb iff (tr.op == AXI_WRITE) {
            bins all_ones   = {4'b1111};
            bins single_b0  = {4'b0001};
            bins single_b1  = {4'b0010};
            bins single_b2  = {4'b0100};
            bins single_b3  = {4'b1000};
            bins half_lower = {4'b0011};
            bins half_upper = {4'b1100};
            bins split_mid  = {4'b0110};
            bins split_out  = {4'b1001};
            bins others     = default;
        }

        // 5. Register Types
        cp_reg_type: coverpoint reg_type {
            bins rw  = {REG_RW};
            bins ro  = {REG_RO};
            bins wo  = {REG_WO};
            bins w1c = {REG_W1C};
            bins unk = {REG_UNKNOWN};
        }

        // 6. Explicit W1C Verification
        cp_w1c_event: coverpoint (tr.op == AXI_WRITE && tr.addr[7:0] == 8'h0C && tr.resp == 2'b00) {
            bins w1c_cleared = {1};
        }

        // Cross Coverage (With Impossible Hardware Responses Ignored)

        cx_op_addr: cross cp_op, cp_addr;
        
        // Ultimate Permission Check: Read/Write vs Register Type vs Response
        cx_op_regtype_resp: cross cp_op, cp_reg_type, cp_resp {
            // Impossible to successfully write to an RO register
            ignore_bins ro_write_okay = binsof(cp_op.write) && binsof(cp_reg_type.ro) && binsof(cp_resp.okay);
            
            // Impossible to successfully read from a WO register
            ignore_bins wo_read_okay  = binsof(cp_op.read)  && binsof(cp_reg_type.wo) && binsof(cp_resp.okay);
            
            // Impossible to get OKAY for an invalid/unknown address
            ignore_bins unk_okay      = binsof(cp_reg_type.unk) && binsof(cp_resp.okay);
        }

    endgroup

    function new(string name = "axi_coverage", uvm_component parent);
        super.new(name, parent);
        cg_axi_trans = new();
    endfunction

    virtual function void write(axi_seq_item t);
        $cast(tr, t);
        
        // Derive Register Permission Type dynamically
        case (tr.addr[7:0])
            8'h04, 8'h14, 8'h18: reg_type = REG_RO;  
            8'h10:               reg_type = REG_WO;  
            8'h0C:               reg_type = REG_W1C; 
            default: begin
                if (tr.addr[7:0] <= 8'h7C) reg_type = REG_RW;
                else reg_type = REG_UNKNOWN;
            end
        endcase

        cg_axi_trans.sample();
    endfunction

    // Report Phase

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("COV", "=================================================", UVM_LOW)
        `uvm_info("COV", " PURE BUS-OBSERVABLE COVERAGE BREAKDOWN", UVM_LOW)
        `uvm_info("COV", "=================================================", UVM_LOW)
        `uvm_info("COV", $sformatf("  cp_op           : %3.2f%%", cg_axi_trans.cp_op.get_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  cp_addr         : %3.2f%%", cg_axi_trans.cp_addr.get_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  cp_resp         : %3.2f%%", cg_axi_trans.cp_resp.get_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  cp_strb         : %3.2f%%", cg_axi_trans.cp_strb.get_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  cp_reg_type     : %3.2f%%", cg_axi_trans.cp_reg_type.get_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  cp_w1c_event    : %3.2f%%", cg_axi_trans.cp_w1c_event.get_coverage()), UVM_LOW)
        `uvm_info("COV", "-------------------------------------------------", UVM_LOW)
        `uvm_info("COV", $sformatf("  TOTAL FUNCTIONAL COVERAGE: %3.2f%%", cg_axi_trans.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", "=================================================", UVM_LOW)
    endfunction

endclass : axi_coverage

`endif 
