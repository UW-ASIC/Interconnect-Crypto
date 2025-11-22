# # tb/test_ack_bus_top.py
# # SPDX-License-Identifier: Apache-2.0

# import cocotb
# from cocotb.triggers import Timer

# async def settle():
#     await Timer(1, units="ns")

# def read_ready_tuple(dut):
#     return (
#         int(dut.uo_out[0].value),
#         int(dut.uo_out[1].value),
#         int(dut.uo_out[2].value),
#         int(dut.uo_out[3].value),
#     )

# # Test 1: Bus valid behavior
# # Any valid input asserts the bus
# @cocotb.test()
# async def test_bus_valid(dut):
#     # idle
#     dut.ui_in[0].value = 0; dut.ui_in[1].value = 0
#     dut.ui_in[2].value = 0; dut.ui_in[3].value = 0
#     await settle()
#     assert int(dut.uo_out[6].value) == 0
#     assert read_ready_tuple(dut) == (0,0,0,0)

#     # single requesters
#     dut.ui_in[0].value = 1; await settle()
#     assert int(dut.uo_out[6].value) == 1
#     assert int(dut.uo_out[5:4].value) == 0b00
#     assert read_ready_tuple(dut) == (1,0,0,0)

#     dut.ui_in[0].value = 0; dut.ui_in[1].value = 1; await settle()
#     assert int(dut.uo_out[5:4].value) == 0b01
#     assert read_ready_tuple(dut) == (0,1,0,0)

#     dut.ui_in[1].value = 0; dut.ui_in[2].value = 1; await settle()
#     assert int(dut.uo_out[5:4].value) == 0b10
#     assert read_ready_tuple(dut) == (0,0,1,0)

#     dut.ui_in[2].value = 0; dut.ui_in[3].value = 1; await settle()
#     assert int(dut.uo_out[5:4].value) == 0b11
#     assert read_ready_tuple(dut) == (0,0,0,1)

# # Test 2: Priority behavior
# # When multiple requesters are active, MEM > SHA > AES > CTRL
# @cocotb.test()
# async def test_priority(dut):
#     # all assert -> MEM wins
#     dut.ui_in[0].value = 1; dut.ui_in[1].value = 1
#     dut.ui_in[2].value = 1; dut.ui_in[3].value = 1
#     await settle()
#     assert int(dut.uo_out[6].value) == 1
#     assert int(dut.uo_out[5:4].value) == 0b00
#     assert read_ready_tuple(dut) == (1,0,0,0)

#     # SHA vs AES vs CTRL -> SHA wins
#     dut.ui_in[0].value = 0; dut.ui_in[1].value = 1
#     dut.ui_in[2].value = 1; dut.ui_in[3].value = 1
#     await settle()
#     assert int(dut.uo_out[5:4].value) == 0b01
#     assert read_ready_tuple(dut) == (0,1,0,0)

#     # AES vs CTRL -> AES wins
#     dut.ui_in[1].value = 0; dut.ui_in[2].value = 1; dut.ui_in[3].value = 1
#     await settle()
#     assert int(dut.uo_out[5:4].value) == 0b10
#     assert read_ready_tuple(dut) == (0,0,1,0)

# # Test 3: Combinational behavior
# # Changes in requests are reflected immediately in the same cycle
# @cocotb.test()
# async def test_combinational_same_cycle(dut):
#     # Multiple → MEM wins, then flip to SHA-only without a clock
#     dut.ui_in[0].value = 1; dut.ui_in[1].value = 1
#     dut.ui_in[2].value = 1; dut.ui_in[3].value = 1
#     await settle()
#     assert int(dut.uo_out[5:4].value) == 0b00
#     assert read_ready_tuple(dut) == (1,0,0,0)

#     # flip to SHA-only
#     dut.ui_in[0].value = 0; dut.ui_in[1].value = 1
#     dut.ui_in[2].value = 0; dut.ui_in[3].value = 0
#     await settle()
#     assert int(dut.uo_out[5:4].value) == 0b01
#     assert read_ready_tuple(dut) == (0,1,0,0)

# # Test 4: No stale grants
# # As soon as another requester takes over, the previous grant is revoked
# @cocotb.test()
# async def test_no_stale_grant(dut):
#     # Start with MEM+SHA asserted -> MEM (00) wins
#     dut.ui_in[0].value = 1
#     dut.ui_in[1].value = 1
#     dut.ui_in[2].value = 0
#     dut.ui_in[3].value = 0
#     await Timer(1, units="ns")
#     assert int(dut.uo_out[6].value) == 1, "event should be 1"
#     assert int(dut.uo_out[5:4].value) == 0b00, "MEM should win"
#     assert (
#         int(dut.uo_out[0].value),
#         int(dut.uo_out[1].value),
#         int(dut.uo_out[2].value),
#         int(dut.uo_out[3].value),
#     ) == (1,0,0,0), "grant must be one-hot to MEM"

#     # Drop MEM while SHA remains -> grant must switch to SHA immediately
#     dut.ui_in[0].value = 0
#     await Timer(1, units="ns")
#     assert int(dut.uo_out[6].value) == 1, "event should remain 1"
#     assert int(dut.uo_out[5:4].value) == 0b01, "SHA should take over"
#     assert (
#         int(dut.uo_out[0].value),
#         int(dut.uo_out[1].value),
#         int(dut.uo_out[2].value),
#         int(dut.uo_out[3].value),
#     ) == (0,1,0,0), "grant must hand off to SHA with no stale MEM grant"

#     # Now switch to CTRL-only -> grant must move to CTRL
#     dut.ui_in[1].value  = 0
#     dut.ui_in[3].value = 1
#     await Timer(1, units="ns")
#     assert int(dut.uo_out[5:4].value) == 0b11, "CTRL should win"
#     assert (
#         int(dut.uo_out[0].value),
#         int(dut.uo_out[1].value),
#         int(dut.uo_out[2].value),
#         int(dut.uo_out[3].value),
#     ) == (0,0,0,1), "grant must be one-hot to CTRL"

#     # Finally drop CTRL -> bus idles, no grants
#     dut.ui_in[3].value = 0
#     await Timer(1, units="ns")
#     assert int(dut.uo_out[6].value) == 0, "event should drop to 0 when no requests"
#     assert (
#         int(dut.uo_out[0].value),
#         int(dut.uo_out[1].value),
#         int(dut.uo_out[2].value),
#         int(dut.uo_out[3].value),
#     ) == (0,0,0,0), "no grants when idle"

# test.py
# cocotb for TinyTapeout wrapper (tt_um_example)
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer

# ---- helpers mapped to project.v bit layout ----
def _uo_out_int(dut) -> int:
    return int(dut.uo_out.value)

def read_event(dut) -> int:
    # uo_out[6]
    return (_uo_out_int(dut) >> 6) & 0x1

def read_winner(dut) -> int:
    # uo_out[5:4]
    return (_uo_out_int(dut) >> 4) & 0b11

def read_ready_tuple(dut):
    # uo_out[3:0] = (ctrl is bit3, aes bit2, sha bit1, mem bit0)
    x = _uo_out_int(dut)
    mem  = (x >> 0) & 0x1
    sha  = (x >> 1) & 0x1
    aes  = (x >> 2) & 0x1
    ctrl = (x >> 3) & 0x1
    return (mem, sha, aes, ctrl)

async def drive_requests(dut, mem=0, sha=0, aes=0, ctrl=0):
    # ui_in[3:0] -> {ctrl,aes,sha,mem}
    base = int(dut.ui_in.value) & 0xF0
    dut.ui_in.value = base | (ctrl << 3) | (aes << 2) | (sha << 1) | (mem << 0)
    # combinational settle
    await Timer(1, units="ns")

@cocotb.test()
async def test_bus_valid(dut):
    # clock/reset like TT template (not strictly needed, but harmless)
    cocotb.start_soon(Clock(dut.clk, 10, units="us").start())
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)

    # idle
    await drive_requests(dut, 0,0,0,0)
    assert read_event(dut) == 0, "idle: ack_event should be 0"
    assert read_ready_tuple(dut) == (0,0,0,0), "idle: no grants"

    # single requesters
    await drive_requests(dut, 1,0,0,0)  # MEM
    assert read_event(dut) == 1
    assert read_winner(dut) == 0b00
    assert read_ready_tuple(dut) == (1,0,0,0)

    await drive_requests(dut, 0,1,0,0)  # SHA
    assert read_event(dut) == 1
    assert read_winner(dut) == 0b01
    assert read_ready_tuple(dut) == (0,1,0,0)

    await drive_requests(dut, 0,0,1,0)  # AES
    assert read_event(dut) == 1
    assert read_winner(dut) == 0b10
    assert read_ready_tuple(dut) == (0,0,1,0)

    await drive_requests(dut, 0,0,0,1)  # CTRL
    assert read_event(dut) == 1
    assert read_winner(dut) == 0b11
    assert read_ready_tuple(dut) == (0,0,0,1)

@cocotb.test()
async def test_priority(dut):
    await drive_requests(dut, 1,1,1,1)   # all -> MEM wins
    assert read_event(dut) == 1
    assert read_winner(dut) == 0b00
    assert read_ready_tuple(dut) == (1,0,0,0)

    await drive_requests(dut, 0,1,1,1)   # SHA,AES,CTRL -> SHA wins
    assert read_winner(dut) == 0b01
    assert read_ready_tuple(dut) == (0,1,0,0)

    await drive_requests(dut, 0,0,1,1)   # AES,CTRL -> AES wins
    assert read_winner(dut) == 0b10
    assert read_ready_tuple(dut) == (0,0,1,0)

@cocotb.test()
async def test_combinational_same_cycle(dut):
    await drive_requests(dut, 1,1,1,1)
    assert read_event(dut) == 1
    assert read_winner(dut) == 0b00
    assert read_ready_tuple(dut) == (1,0,0,0)

    await drive_requests(dut, 0,1,0,0)   # flip to SHA-only
    assert read_winner(dut) == 0b01
    assert read_ready_tuple(dut) == (0,1,0,0)

@cocotb.test()
async def test_no_stale_grant(dut):
    # MEM + SHA -> MEM wins
    await drive_requests(dut, 1,1,0,0)
    assert read_event(dut) == 1
    assert read_winner(dut) == 0b00
    assert read_ready_tuple(dut) == (1,0,0,0)

    # Drop MEM, SHA remains -> handoff to SHA
    await drive_requests(dut, 0,1,0,0)
    assert read_event(dut) == 1
    assert read_winner(dut) == 0b01
    assert read_ready_tuple(dut) == (0,1,0,0)

    # Switch to CTRL-only
    await drive_requests(dut, 0,0,0,1)
    assert read_winner(dut) == 0b11
    assert read_ready_tuple(dut) == (0,0,0,1)

    # Drop CTRL -> idle
    await drive_requests(dut, 0,0,0,0)
    assert read_event(dut) == 0
    assert read_ready_tuple(dut) == (0,0,0,0)