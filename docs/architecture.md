# Hardware Architecture Specification: AXI4-Lite Slave IP

## 1. System Overview
The AXI4-Lite Slave IP operates as a high-performance memory-mapped bridge. It sits between a high-speed AMBA AXI4-Lite interconnect (the Master) and localized System-on-Chip (SoC) hardware logic. Its primary function is to translate asynchronous, multi-channel AXI transactions into deterministic register reads and writes, while enforcing strict hardware-level memory protection.

---

## 2. Interface Definitions

### 2.1 West-Bound Interface (AXI4-Lite Bus)
The IP implements the standard 32-bit AXI4-Lite protocol, utilizing all 5 independent channels:
* **Write Address Channel (AW):** `awaddr`, `awprot`, `awvalid`, `awready`
* **Write Data Channel (W):** `wdata`, `wstrb`, `wvalid`, `wready`
* **Write Response Channel (B):** `bresp`, `bvalid`, `bready`
* **Read Address Channel (AR):** `araddr`, `arprot`, `arvalid`, `arready`
* **Read Data Channel (R):** `rdata`, `rresp`, `rvalid`, `rready`

### 2.2 East-Bound Interface (SoC Hardware Boundary)
The slave exposes a simple, flat interface to the rest of the silicon:
* **`hw_status_in` (32-bit):** Incoming read-only hardware status. Mapped to the `STATUS` register.
* **`hw_data_in` (32-bit):** Incoming read-only data payload. Mapped to the `DATA_OUT` register.
* **`hw_ctrl_out` (32-bit):** Outgoing control signals driven by software. Mapped to the `CTRL` register.
* **`hw_data_out` (32-bit):** Outgoing data payload driven by software. Mapped to the `DATA_IN` register.

---

## 3. Clocking and Reset Architecture
* **Clock (`aclk`):** The design exists entirely in a single clock domain. All FSM state transitions and register updates occur on the rising edge of `aclk`.
* **Reset (`aresetn`):** The design utilizes an active-low, asynchronous reset. When `aresetn` is asserted (`1'b0`), all AXI `VALID` and `READY` signals are immediately driven low to prevent X-state propagation, and all internal registers return to their default reset values.

---

## 4. Write Channel FSM & Decoupling Logic
Unlike simplified AXI implementations that require `AWVALID` and `WVALID` to assert simultaneously, this architecture fully supports **Write Channel Independence**. The Address and Data channels are deeply decoupled.

### 4.1 Handshake Capture
The RTL utilizes two independent capture flags:
* `aw_received`: Asserts when `AWVALID && AWREADY` is true.
* `w_received`: Asserts when `WVALID && WREADY` is true.

The Master may send the Address first, the Data first, or both simultaneously. The Slave holds the data in staging flops until both `aw_received` and `w_received` evaluate to true.

### 4.2 Byte Strobe (`WSTRB`) Application
Once a write is committed, the 4-bit `WSTRB` signal acts as a byte-enable mask. The RTL uses a segmented assignment block to update only the specific bytes authorized by the master:

```verilog
if (wstrb[0]) reg_file[addr][7:0]   <= wdata[7:0];
if (wstrb[1]) reg_file[addr][15:8]  <= wdata[15:8];
if (wstrb[2]) reg_file[addr][23:16] <= wdata[23:16];
if (wstrb[3]) reg_file[addr][31:24] <= wdata[31:24];
```

---

## 5. Read Channel FSM
The Read FSM operates independently of the Write FSM and uses a structured three-phase pipeline:

* **Address Phase:** Captures `araddr` upon a valid `ARVALID && ARREADY` handshake.
* **Decode & Fetch Phase:** Validates the address against the localized memory map. If the address is valid, the target register's data is muxed onto the internal read bus.
* **Response Phase:** Asserts `RVALID` and awaits `RREADY` from the Master. Output read data is held perfectly stable during Master backpressure stalls.

---

## 6. Memory Protection & Error Routing (`SLVERR`)
The IP features robust address decoding and hardware-level permission enforcement. Any illegal access prevents register mutation and forces the response channels (`BRESP` or `RRESP`) to return a `2'b10` (`SLVERR`) code.

### 6.1 Address Boundaries
* The valid address space is strictly bounded between `0x00` and `0x7C`.
* Accessing unmapped memory spaces from `0x80` to `0xFF` terminates the cycle cleanly and generates a `SLVERR`.

### 6.2 Permission Enforcement
* **Read-Only (RO):** Writes to `STATUS` (`0x04`), `VERSION` (`0x14`), and `DATA_OUT` (`0x18`) are sunk by hardware and flagged with a write `SLVERR`.
* **Write-Only (WO):** Reads from `DATA_IN` (`0x10`) return `0x00000000` on the bus and are flagged with a read `SLVERR`.
* **Write-1-To-Clear (W1C):** Writes to `IRQ_STAT` (`0x0C`) pass through a specialized bitwise mask. Only bits driven high (`1`) by the Master clear their respective localized registers; bits driven low (`0`) are ignored.