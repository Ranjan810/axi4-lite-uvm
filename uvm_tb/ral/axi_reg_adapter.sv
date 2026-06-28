`ifndef AXI_REG_ADAPTER_SV
`define AXI_REG_ADAPTER_SV

class axi_reg_adapter extends uvm_reg_adapter;

    `uvm_object_utils(axi_reg_adapter)

    function new(string name = "axi_reg_adapter");
        super.new(name);
        // AXI4-Lite supports byte enables, but UVM RAL defaults to word-level
        supports_byte_enable = 1;
        provides_responses   = 0;
    endfunction

    // Translate UVM RAL Operation -> AXI4-Lite Sequence Item

    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        axi_seq_item item = axi_seq_item::type_id::create("item");
        
        item.op   = (rw.kind == UVM_READ) ? AXI_READ : AXI_WRITE;
        item.addr = rw.addr;
        item.data = rw.data;
        item.strb = rw.byte_en;
        
        // Use default rapid timing for RAL back-door/front-door accesses
        item.aw_delay     = 0;
        item.w_delay      = 0;
        item.bready_delay = 0;
        item.ar_delay     = 0;
        item.rready_delay = 0;
        item.idle_cycles  = 0;

        return item;
    endfunction

    // Translate AXI4-Lite Sequence Item -> UVM RAL Operation

    virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
        axi_seq_item item;
        
        if (!$cast(item, bus_item)) begin
            `uvm_fatal("ADAPT_CAST", "Failed to cast bus_item to axi_seq_item")
        end
        
        rw.kind    = (item.op == AXI_READ) ? UVM_READ : UVM_WRITE;
        rw.addr    = item.addr;
        rw.data    = item.data;
        rw.status  = (item.resp == 2'b00) ? UVM_IS_OK : UVM_NOT_OK;
    endfunction

endclass : axi_reg_adapter

`endif 
