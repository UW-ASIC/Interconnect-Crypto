# tb/test_ack_bus_top.py
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.triggers import Timer

async def settle():
    await Timer(1, units="ns")

def read_ready_tuple(dut):
    return (
        int(dut.ack_ready_to_mem.value),
        int(dut.ack_ready_to_sha.value),
        int(dut.ack_ready_to_aes.value),
        int(dut.ack_ready_to_ctrl.value),
    )

# Test 1: Bus valid behavior
# Any valid input asserts the bus
@cocotb.test()
async def test_bus_valid(dut):
    # idle
    dut.req_mem.value = 0; dut.req_sha.value = 0
    dut.req_aes.value = 0; dut.req_ctrl.value = 0
    await settle()
    assert int(dut.ack_event.value) == 0
    assert read_ready_tuple(dut) == (0,0,0,0)

    # single requesters
    dut.req_mem.value = 1; await settle()
    assert int(dut.ack_event.value) == 1
    assert int(dut.winner_source_id.value) == 0b00
    assert read_ready_tuple(dut) == (1,0,0,0)

    dut.req_mem.value = 0; dut.req_sha.value = 1; await settle()
    assert int(dut.winner_source_id.value) == 0b01
    assert read_ready_tuple(dut) == (0,1,0,0)

    dut.req_sha.value = 0; dut.req_aes.value = 1; await settle()
    assert int(dut.winner_source_id.value) == 0b10
    assert read_ready_tuple(dut) == (0,0,1,0)

    dut.req_aes.value = 0; dut.req_ctrl.value = 1; await settle()
    assert int(dut.winner_source_id.value) == 0b11
    assert read_ready_tuple(dut) == (0,0,0,1)

# Test 2: Priority behavior
# When multiple requesters are active, MEM > SHA > AES > CTRL
@cocotb.test()
async def test_priority(dut):
    # all assert -> MEM wins
    dut.req_mem.value = 1; dut.req_sha.value = 1
    dut.req_aes.value = 1; dut.req_ctrl.value = 1
    await settle()
    assert int(dut.ack_event.value) == 1
    assert int(dut.winner_source_id.value) == 0b00
    assert read_ready_tuple(dut) == (1,0,0,0)

    # SHA vs AES vs CTRL -> SHA wins
    dut.req_mem.value = 0; dut.req_sha.value = 1
    dut.req_aes.value = 1; dut.req_ctrl.value = 1
    await settle()
    assert int(dut.winner_source_id.value) == 0b01
    assert read_ready_tuple(dut) == (0,1,0,0)

    # AES vs CTRL -> AES wins
    dut.req_sha.value = 0; dut.req_aes.value = 1; dut.req_ctrl.value = 1
    await settle()
    assert int(dut.winner_source_id.value) == 0b10
    assert read_ready_tuple(dut) == (0,0,1,0)

# Test 3: Combinational behavior
# Changes in requests are reflected immediately in the same cycle
@cocotb.test()
async def test_combinational_same_cycle(dut):
    # Multiple → MEM wins, then flip to SHA-only without a clock
    dut.req_mem.value = 1; dut.req_sha.value = 1
    dut.req_aes.value = 1; dut.req_ctrl.value = 1
    await settle()
    assert int(dut.winner_source_id.value) == 0b00
    assert read_ready_tuple(dut) == (1,0,0,0)

    # flip to SHA-only
    dut.req_mem.value = 0; dut.req_sha.value = 1
    dut.req_aes.value = 0; dut.req_ctrl.value = 0
    await settle()
    assert int(dut.winner_source_id.value) == 0b01
    assert read_ready_tuple(dut) == (0,1,0,0)

# Test 4: No stale grants
# As soon as another requester takes over, the previous grant is revoked
@cocotb.test()
async def test_no_stale_grant(dut):
    # Start with MEM+SHA asserted -> MEM (00) wins
    dut.req_mem.value = 1
    dut.req_sha.value = 1
    dut.req_aes.value = 0
    dut.req_ctrl.value = 0
    await Timer(1, units="ns")
    assert int(dut.ack_event.value) == 1, "event should be 1"
    assert int(dut.winner_source_id.value) == 0b00, "MEM should win"
    assert (
        int(dut.ack_ready_to_mem.value),
        int(dut.ack_ready_to_sha.value),
        int(dut.ack_ready_to_aes.value),
        int(dut.ack_ready_to_ctrl.value),
    ) == (1,0,0,0), "grant must be one-hot to MEM"

    # Drop MEM while SHA remains -> grant must switch to SHA immediately
    dut.req_mem.value = 0
    await Timer(1, units="ns")
    assert int(dut.ack_event.value) == 1, "event should remain 1"
    assert int(dut.winner_source_id.value) == 0b01, "SHA should take over"
    assert (
        int(dut.ack_ready_to_mem.value),
        int(dut.ack_ready_to_sha.value),
        int(dut.ack_ready_to_aes.value),
        int(dut.ack_ready_to_ctrl.value),
    ) == (0,1,0,0), "grant must hand off to SHA with no stale MEM grant"

    # Now switch to CTRL-only -> grant must move to CTRL
    dut.req_sha.value  = 0
    dut.req_ctrl.value = 1
    await Timer(1, units="ns")
    assert int(dut.winner_source_id.value) == 0b11, "CTRL should win"
    assert (
        int(dut.ack_ready_to_mem.value),
        int(dut.ack_ready_to_sha.value),
        int(dut.ack_ready_to_aes.value),
        int(dut.ack_ready_to_ctrl.value),
    ) == (0,0,0,1), "grant must be one-hot to CTRL"

    # Finally drop CTRL -> bus idles, no grants
    dut.req_ctrl.value = 0
    await Timer(1, units="ns")
    assert int(dut.ack_event.value) == 0, "event should drop to 0 when no requests"
    assert (
        int(dut.ack_ready_to_mem.value),
        int(dut.ack_ready_to_sha.value),
        int(dut.ack_ready_to_aes.value),
        int(dut.ack_ready_to_ctrl.value),
    ) == (0,0,0,0), "no grants when idle"
