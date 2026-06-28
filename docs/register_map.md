# Programmer's Reference: Register Map

**Base Address:** dynamically mapped by interconnect (e.g., `0x4000_0000`)  
**Data Width:** 32-bit

## Address Space Summary

| Offset | Register Name | Type | Reset Value | Description |
| :--- | :--- | :---: | :--- | :--- |
| `0x00` | `CTRL` | RW | `0x00000000` | Main Control Register (Bits 31:3 Reserved) |
| `0x04` | `STATUS` | RO | `0x00000000` | Hardware Status (Driven by `hw_status_in`) |
| `0x08` | `IRQ_EN` | RW | `0x00000000` | Interrupt Enable Mask |
| `0x0C` | `IRQ_STAT` | W1C | `0x00000000` | Interrupt Status (Write 1 to Clear) |
| `0x10` | `DATA_IN` | WO | `0x00000000` | Data to Hardware (`hw_data_out`) |
| `0x14` | `VERSION` | RO | `0x01000000` | IP Version / Magic Number |
| `0x18` | `DATA_OUT` | RO | `0x00000000` | Data from Hardware (`hw_data_in`) |
| `0x1C-0x7C` | `CFG_REGS[0:24]`| RW | `0x00000000` | Array of 25 Configuration Registers |
| `0x80-0xFF` | `RESERVED` | -- | -- | Unmapped memory space (Returns `SLVERR`) |

## Permission Architecture
1. **Read-Only (RO):** Any write attempt to `STATUS`, `VERSION`, or `DATA_OUT` is blocked and returns `SLVERR`.
2. **Write-Only (WO):** Any read attempt from `DATA_IN` returns `SLVERR`.
3. **Write-1-To-Clear (W1C):** Writing a `1` to any bit in `IRQ_STAT` clears that specific bit to `0`. Writing a `0` has no effect.
4. **Reserved Space:** Accessing address `0x80` or higher returns `SLVERR`.