`ifndef AXI_REG_BLOCK_SV
`define AXI_REG_BLOCK_SV

// Individual Register Definitions

// Control Register (RW with Reserved Bits)
class reg_ctrl extends uvm_reg;
    `uvm_object_utils(reg_ctrl)
    
    uvm_reg_field enable;       // Bit 0
    uvm_reg_field soft_reset;   // Bit 1
    uvm_reg_field global_irq;   // Bit 2
    // Bits 31:3 are reserved
    
    function new(string name = "reg_ctrl");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction
    
    virtual function void build();
        enable     = uvm_reg_field::type_id::create("enable");
        soft_reset = uvm_reg_field::type_id::create("soft_reset");
        global_irq = uvm_reg_field::type_id::create("global_irq");
        
        // configure: parent, size, lsb_pos, access, volatile, reset, has_reset, is_rand, individually_accessible
        enable.configure(this, 1, 0, "RW", 0, 1'b0, 1, 1, 1);
        soft_reset.configure(this, 1, 1, "RW", 0, 1'b0, 1, 1, 1);
        global_irq.configure(this, 1, 2, "RW", 0, 1'b0, 1, 1, 1);
    endfunction
endclass

// IRQ Status Register (Write-One-To-Clear)
class reg_irq_status extends uvm_reg;
    `uvm_object_utils(reg_irq_status)
    
    uvm_reg_field irq_flags; 
    
    function new(string name = "reg_irq_status");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction
    
    virtual function void build();
        irq_flags = uvm_reg_field::type_id::create("irq_flags");
        irq_flags.configure(this, 32, 0, "W1C", 1, 32'h0, 1, 1, 1);
    endfunction
endclass

// Generic 32-bit RW Configuration Register
class reg_config extends uvm_reg;
    `uvm_object_utils(reg_config)
    
    uvm_reg_field cfg_data; 
    
    function new(string name = "reg_config");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction
    
    virtual function void build();
        cfg_data = uvm_reg_field::type_id::create("cfg_data");
        cfg_data.configure(this, 32, 0, "RW", 0, 32'h0, 1, 1, 1);
    endfunction
endclass

// Generic 32-bit RO Status Register (Hardware Driven)
class reg_status_ro extends uvm_reg;
    `uvm_object_utils(reg_status_ro)
    
    uvm_reg_field stat_data; 
    
    function new(string name = "reg_status_ro");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction
    
    virtual function void build();
        stat_data = uvm_reg_field::type_id::create("stat_data");
        stat_data.configure(this, 32, 0, "RO", 1, 32'h0, 1, 0, 1);
    endfunction
endclass

// The Top-Level Register Block

class axi_reg_block extends uvm_reg_block;

    `uvm_object_utils(axi_reg_block)

    // Register Handles
    rand reg_ctrl       ctrl;
    rand reg_status_ro  status;
    rand reg_config     irq_enable;
    rand reg_irq_status irq_status;
    rand reg_status_ro  version;
    rand reg_config     cfg_regs[25];

    function new(string name = "axi_reg_block");
        super.new(name, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        // Create an address map for AXI4-Lite: name, base_addr, byte_width, endianness
        default_map = create_map("default_map", 0, 4, UVM_LITTLE_ENDIAN);

        // Instantiate and build registers
        ctrl = reg_ctrl::type_id::create("ctrl");
        ctrl.configure(this, null);
        ctrl.build();
        default_map.add_reg(ctrl, 32'h00, "RW");

        status = reg_status_ro::type_id::create("status");
        status.configure(this, null);
        status.build();
        default_map.add_reg(status, 32'h04, "RO");

        irq_enable = reg_config::type_id::create("irq_enable");
        irq_enable.configure(this, null);
        irq_enable.build();
        default_map.add_reg(irq_enable, 32'h08, "RW");

        irq_status = reg_irq_status::type_id::create("irq_status");
        irq_status.configure(this, null);
        irq_status.build();
        default_map.add_reg(irq_status, 32'h0C, "RW"); // RAL map access is RW, field handles W1C

        version = reg_status_ro::type_id::create("version");
        version.configure(this, null);
        version.build();
        default_map.add_reg(version, 32'h14, "RO");

        // Instantiate Configuration Registers
        foreach (cfg_regs[i]) begin
            cfg_regs[i] = reg_config::type_id::create($sformatf("cfg_regs[%0d]", i));
            cfg_regs[i].configure(this, null);
            cfg_regs[i].build();
            default_map.add_reg(cfg_regs[i], 32'h1C + (i * 4), "RW");
        end
        
        lock_model();
    endfunction

endclass : axi_reg_block

`endif 
