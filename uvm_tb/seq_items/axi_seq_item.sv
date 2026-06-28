`ifndef AXI_SEQ_ITEM_SV
`define AXI_SEQ_ITEM_SV

typedef enum bit {
    AXI_READ  = 1'b0,
    AXI_WRITE = 1'b1
} axi_op_t;

class axi_seq_item extends uvm_sequence_item;

    // Transaction Data

    rand axi_op_t       op;
    rand bit [31:0]     addr;
    rand bit [31:0]     data;
    rand bit [3:0]      strb;
    
    // Response (Sampled from the bus)
    bit [1:0]           resp;

    // Protocol Timing Knobs (Clock Cycles)

    rand int unsigned   aw_delay;      
    rand int unsigned   w_delay;       
    rand int unsigned   bready_delay;  
    rand int unsigned   ar_delay;      
    rand int unsigned   rready_delay;  
    rand int unsigned   idle_cycles;   // Bus dead-time before this transaction starts

    // Scenario Injection Flags

    rand bit            inject_backpressure; 
    rand bit            illegal_access;      
    rand bit            random_reset;        

    // Factory Registration

    `uvm_object_utils_begin(axi_seq_item)
        `uvm_field_enum  (axi_op_t, op, UVM_ALL_ON)
        `uvm_field_int   (addr,         UVM_ALL_ON)
        `uvm_field_int   (data,         UVM_ALL_ON)
        `uvm_field_int   (strb,         UVM_ALL_ON)
        `uvm_field_int   (resp,         UVM_ALL_ON)
        `uvm_field_int   (aw_delay,     UVM_ALL_ON | UVM_NOCOMPARE)
        `uvm_field_int   (w_delay,      UVM_ALL_ON | UVM_NOCOMPARE)
        `uvm_field_int   (bready_delay, UVM_ALL_ON | UVM_NOCOMPARE)
        `uvm_field_int   (ar_delay,     UVM_ALL_ON | UVM_NOCOMPARE)
        `uvm_field_int   (rready_delay, UVM_ALL_ON | UVM_NOCOMPARE)
        `uvm_field_int   (idle_cycles,  UVM_ALL_ON | UVM_NOCOMPARE)
        `uvm_field_int   (inject_backpressure, UVM_ALL_ON | UVM_NOCOMPARE)
        `uvm_field_int   (illegal_access,      UVM_ALL_ON | UVM_NOCOMPARE)
        `uvm_field_int   (random_reset,        UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_object_utils_end

    // Constraints
    // Base alignment
    constraint c_addr_align {
        addr[1:0] == 2'b00;
    }

    // Default Address Mapping (Legal vs Illegal)
    constraint c_address_space {
        if (illegal_access) {
            addr inside {[32'h0000_0080 : 32'hFFFF_FFFF]}; // Force OOB
        } else {
            addr inside {[32'h0000_0000 : 32'h0000_007C]}; // Legal range
        }
    }

    // Timing & Backpressure rules
    constraint c_delays {
        idle_cycles inside {[0:2]};
        aw_delay    inside {[0:5]};
        w_delay     inside {[0:5]};
        ar_delay    inside {[0:5]};

        if (inject_backpressure) {
            bready_delay inside {[5:15]};
            rready_delay inside {[5:15]};
        } else {
            bready_delay inside {[0:2]};
            rready_delay inside {[0:2]};
        }
    }

    constraint c_read_strb {
        if (op == AXI_READ) strb == 4'h0;
    }

    // Rare occurrence constraints to keep simulations stable but interesting
    constraint c_rare_events {
        inject_backpressure dist {0 := 80, 1 := 20};
        illegal_access      dist {0 := 90, 1 := 10};
        random_reset        dist {0 := 99, 1 := 1};
    }

    function new(string name = "axi_seq_item");
        super.new(name);
    endfunction

endclass : axi_seq_item

`endif 
