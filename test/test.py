import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles

def _uo_out_int(dut) -> int:
    return int(dut.uo_out.value)


def read_event(dut) -> int:
    """Return ack_event (bit 6 of uo_out)."""
    return (_uo_out_int(dut) >> 6) & 0x1


def read_winner(dut) -> int:
    """Return winner_source_id (bits 5:4 of uo_out)."""
    return (_uo_out_int(dut) >> 4) & 0b11


def read_ready_tuple(dut):
    """Return (mem, sha, aes, ctrl) from uo_out[3:0]."""
    x = _uo_out_int(dut)
    mem  = (x >> 0) & 0x1
    sha  = (x >> 1) & 0x1
    aes  = (x >> 2) & 0x1
    ctrl = (x >> 3) & 0x1
    return (mem, sha, aes, ctrl)


async def drive_requests(dut, mem=0, sha=0, aes=0, ctrl=0):
    """Drive ui_in[3:0] while preserving the upper nibble.

    Mapping is ui_in[3:0] = {ctrl, aes, sha, mem}.
    """
    base = int(dut.ui_in.value) & 0xF0
    dut.ui_in.value = base | (ctrl << 3) | (aes << 2) | (sha << 1) | (mem << 0)
    # small delay to let combinational logic settle
    await Timer(1, units="ns")


async def init_dut(dut):
    """Common clock / reset init similar to the TinyTapeout template."""
    cocotb.start_soon(Clock(dut.clk, 10, units="us").start())
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)


# --------------------------------------------------------------------
# Test 1: bus-valid behaviour (ack_event and single requesters)
# --------------------------------------------------------------------

@cocotb.test()
async def test_bus_valid(dut):
    await init_dut(dut)

    # idle
    await drive_requests(dut, 0, 0, 0, 0)
    assert read_event(dut) == 0, "idle: ack_event should be 0"
    assert read_ready_tuple(dut) == (0, 0, 0, 0), "idle: no grants"

    # single requesters – winner must match requester and grant must be one-hot
    await drive_requests(dut, 1, 0, 0, 0)  # MEM
    assert read_event(dut) == 1
    assert read_winner(dut) == 0b00
    assert read_ready_tuple(dut) == (1, 0, 0, 0)

    await drive_requests(dut, 0, 1, 0, 0)  # SHA
    assert read_event(dut) == 1
    assert read_winner(dut) == 0b01
    assert read_ready_tuple(dut) == (0, 1, 0, 0)

    await drive_requests(dut, 0, 0, 1, 0)  # AES
    assert read_event(dut) == 1
    assert read_winner(dut) == 0b10
    assert read_ready_tuple(dut) == (0, 0, 1, 0)

    await drive_requests(dut, 0, 0, 0, 1)  # CTRL
    assert read_event(dut) == 1
    assert read_winner(dut) == 0b11
    assert read_ready_tuple(dut) == (0, 0, 0, 1)


# --------------------------------------------------------------------
# Test 2: static priority (CTRL > MEM > AES > SHA)
# --------------------------------------------------------------------

@cocotb.test()
async def test_priority(dut):
    await init_dut(dut)

    # All requesters active -> CTRL (highest) must win
    await drive_requests(dut, 1, 1, 1, 1)
    assert read_event(dut) == 1
    assert read_winner(dut) == 0b11
    assert read_ready_tuple(dut) == (0, 0, 0, 1)

    # Drop CTRL -> MEM must now win
    await drive_requests(dut, 1, 1, 1, 0)
    assert read_winner(dut) == 0b00
    assert read_ready_tuple(dut) == (1, 0, 0, 0)

    # Drop MEM -> AES must now win (AES + SHA)
    await drive_requests(dut, 0, 1, 1, 0)
    assert read_winner(dut) == 0b10
    assert read_ready_tuple(dut) == (0, 0, 1, 0)

    # Drop AES -> SHA must now win
    await drive_requests(dut, 0, 1, 0, 0)
    assert read_winner(dut) == 0b01
    assert read_ready_tuple(dut) == (0, 1, 0, 0)


# --------------------------------------------------------------------
# Test 3: purely combinational behaviour (same-cycle response)
# --------------------------------------------------------------------

@cocotb.test()
async def test_combinational_same_cycle(dut):
    await init_dut(dut)

    # First, all active -> CTRL wins
    await drive_requests(dut, 1, 1, 1, 1)
    assert read_event(dut) == 1
    assert read_winner(dut) == 0b11
    assert read_ready_tuple(dut) == (0, 0, 0, 1)

    # In the same simulation time frame (just a small #delay via drive_requests),
    # flip to SHA-only and see the winner change immediately.
    await drive_requests(dut, 0, 1, 0, 0)
    assert read_event(dut) == 1
    assert read_winner(dut) == 0b01
    assert read_ready_tuple(dut) == (0, 1, 0, 0)


# --------------------------------------------------------------------
# Test 4: no stale grant when highest-priority drops
# --------------------------------------------------------------------

@cocotb.test()
async def test_no_stale_grant(dut):
    await init_dut(dut)

    # CTRL + MEM -> CTRL wins
    await drive_requests(dut, 1, 0, 0, 1)
    assert read_event(dut) == 1
    assert read_winner(dut) == 0b11
    assert read_ready_tuple(dut) == (0, 0, 0, 1)

    # Drop CTRL, MEM remains -> handoff to MEM
    await drive_requests(dut, 1, 0, 0, 0)
    assert read_event(dut) == 1
    assert read_winner(dut) == 0b00
    assert read_ready_tuple(dut) == (1, 0, 0, 0)

    # Drop MEM -> idle, no grants
    await drive_requests(dut, 0, 0, 0, 0)
    assert read_event(dut) == 0
    assert read_ready_tuple(dut) == (0, 0, 0, 0)
