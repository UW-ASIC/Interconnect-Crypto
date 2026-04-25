import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer, ReadOnly, RisingEdge, FallingEdge

# uio_in bit mapping
VALID_CTRL = 1 << 0
VALID_MEM  = 1 << 1
READY_MEM  = 1 << 2
READY_AES  = 1 << 3
READY_SHA  = 1 << 4
ACK_MEM    = 1 << 5
ACK_AES    = 1 << 6
ACK_SHA    = 1 << 7

# IDs
MEM  = 0b00
SHA  = 0b01
AES  = 0b10
CTRL = 0b11

# opcodes
OP_RD_KEY = 0b00
OP_RD_TXT = 0b01
OP_WR_TXT = 0b10
OP_HASH   = 0b11


def enc_opcode(dest, src, op):
    return ((dest & 0b11) << 4) | ((src & 0b11) << 2) | (op & 0b11)


def get_bit(sig, idx):
    return (int(sig.value) >> idx) & 1


async def settle():
    await Timer(1, "ns")
    await ReadOnly()


async def reset_dut(dut):
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0

    await ClockCycles(dut.clk, 5)

    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    # IMPORTANT: do not call settle() here
    # because settle() ends in ReadOnly phase


@cocotb.test(timeout_time=100, timeout_unit="us")
async def interconnect_smoke_test(dut):
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())

    dut._log.info("Reset start")
    await reset_dut(dut)
    dut._log.info("Reset done")

    # uo_out mapping:
    # [0] ready_out_ctrl
    # [1] ready_out_mem
    # [2] ready_out_aes
    # [3] ready_out_sha
    # [4] dv_rd_grant_mem
    # [5] dv_rd_grant_aes
    # [6] dv_rd_grant_sha
    # [7] ack_ready_out_mem

    dut._log.info("Check reset: ctrl should be ready")
    await settle()
    assert get_bit(dut.uo_out, 0) == 1, "After reset, ready_out_ctrl should be 1"

    # leave ReadOnly phase before driving
    await RisingEdge(dut.clk)

    dut._log.info("Test invalid opcode")

    # invalid hash: dest=MEM is invalid for hash
    invalid_op = enc_opcode(MEM, MEM, OP_HASH)

    dut.ui_in.value = invalid_op
    dut.uio_in.value = VALID_CTRL
    await settle()

    assert get_bit(dut.uo_out, 0) == 1, "Invalid opcode should keep ctrl ready high"
    assert get_bit(dut.uo_out, 4) == 0, "Invalid opcode should not grant MEM dv"
    assert get_bit(dut.uo_out, 5) == 0, "Invalid opcode should not grant AES dv"
    assert get_bit(dut.uo_out, 6) == 0, "Invalid opcode should not grant SHA dv"

    # leave ReadOnly phase before driving
    await RisingEdge(dut.clk)

    dut.uio_in.value = 0
    dut.ui_in.value = 0
    await ClockCycles(dut.clk, 2)

    dut._log.info("Test hash opcode to AES")

    # hash to AES: dest=AES, src=MEM/don't-care, op=HASH
    hash_aes = enc_opcode(AES, MEM, OP_HASH)

    # AES not ready first; ctrl valid high
    dut.ui_in.value = hash_aes
    dut.uio_in.value = VALID_CTRL
    await settle()

    assert get_bit(dut.uo_out, 0) == 0, "Hash should stall ctrl for grant setup"

    # leave ReadOnly phase before clocking/checking next registered grant
    await RisingEdge(dut.clk)
    await settle()

    assert get_bit(dut.uo_out, 5) == 1, "Hash should grant AES dv after stall cycle"
    assert get_bit(dut.uo_out, 0) == 0, "Ctrl should stay stalled while AES not ready"

    # leave ReadOnly phase before driving AES ready
    await RisingEdge(dut.clk)

    # Now AES becomes ready, ctrl should be allowed to handshake
    dut.uio_in.value = VALID_CTRL | READY_AES
    await settle()

    assert get_bit(dut.uo_out, 0) == 1, "Ctrl ready should rise when AES ready"

    # leave ReadOnly phase and take handshake edge
    await RisingEdge(dut.clk)

    # ctrl drops valid
    dut.uio_in.value = READY_AES
    await ClockCycles(dut.clk, 1)
    await settle()

    assert get_bit(dut.uo_out, 5) == 0, "AES dv grant should clear after hash handshake"

    dut._log.info("PASS: reset + invalid opcode + hash opcode smoke test")

@cocotb.test(timeout_time=100, timeout_unit="us")
async def mem_to_aes_smoke_test(dut):
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())

    dut._log.info("Reset start")
    await reset_dut(dut)
    dut._log.info("Reset done")

    # uo_out mapping:
    # [0] ready_out_ctrl
    # [1] ready_out_mem
    # [2] ready_out_aes
    # [3] ready_out_sha
    # [4] dv_rd_grant_mem
    # [5] dv_rd_grant_aes
    # [6] dv_rd_grant_sha
    # [7] ack_ready_out_mem

    await settle()
    assert get_bit(dut.uo_out, 0) == 1, "After reset, ctrl should be ready"

    dut._log.info("Test rd_txt MEM -> AES")

    rd_txt_mem_to_aes = enc_opcode(AES, MEM, OP_RD_TXT)  # 0x21

    # Opcode phase
    await FallingEdge(dut.clk)
    dut.ui_in.value = rd_txt_mem_to_aes
    dut.uio_in.value = VALID_CTRL | READY_MEM | READY_AES

    await settle()
    assert get_bit(dut.uo_out, 0) == 1, "Opcode phase: ctrl should see ready high"

    # Opcode handshake
    await RisingEdge(dut.clk)

    # Address byte 0
    await FallingEdge(dut.clk)
    dut.ui_in.value = 0xAA
    dut.uio_in.value = VALID_CTRL | READY_MEM | READY_AES

    await settle()
    assert get_bit(dut.uo_out, 0) == 1, "Addr byte 0: ctrl should be ready"
    assert get_bit(dut.uo_out, 4) == 1, "After opcode: MEM dv grant should be high"
    assert get_bit(dut.uo_out, 5) == 1, "After opcode: AES dv grant should be high"

    # Address byte 0 handshakes.
    await RisingEdge(dut.clk)
    # Address byte 1
    await FallingEdge(dut.clk)
    dut.ui_in.value = 0xBB
    dut.uio_in.value = VALID_CTRL | READY_MEM | READY_AES

    await settle()
    assert get_bit(dut.uo_out, 0) == 1, "Addr byte 1: ctrl should be ready"

    # Address byte 1 handshakes.
    await RisingEdge(dut.clk)
    # Address byte 2
    await FallingEdge(dut.clk)
    dut.ui_in.value = 0xCC
    dut.uio_in.value = VALID_CTRL | READY_MEM | READY_AES

    await settle()
    assert get_bit(dut.uo_out, 0) == 1, "Addr byte 2: ctrl should be ready"

    # Address byte 2 handshakes.
    await RisingEdge(dut.clk)

    # Module transmission phase
    await settle()

    assert get_bit(dut.uo_out, 1) == 1, "Module transmission: MEM should see ready"
    assert get_bit(dut.uo_out, 4) == 0, "Module transmission: MEM dv grant should be cleared"
    assert get_bit(dut.uo_out, 5) == 1, "Module transmission: AES dv grant should stay high"

    dut._log.info("MEM drives data, then sends ack")

    # MEM drives one data byte
    await FallingEdge(dut.clk)
    dut.ui_in.value = 0x5A
    dut.uio_in.value = VALID_MEM | READY_AES

    await settle()
    assert get_bit(dut.uo_out, 1) == 1, "MEM transmission: MEM should see ready from AES"

    # MEM asserts ack
    await FallingEdge(dut.clk)
    dut.ui_in.value = 0x5A
    dut.uio_in.value = VALID_MEM | READY_AES | ACK_MEM

    await settle()
    assert get_bit(dut.uo_out, 7) == 1, "MEM ack: ack_ready_out_mem should assert"

    # Ack is observed on this rising edge.
    await RisingEdge(dut.clk)

    # Drop MEM valid/ack
    await FallingEdge(dut.clk)
    dut.uio_in.value = READY_AES
    dut.ui_in.value = 0

    await RisingEdge(dut.clk)
    await settle()

    assert get_bit(dut.uo_out, 0) == 1, "After MEM ack: ctrl should be ready again"
    assert get_bit(dut.uo_out, 5) == 0, "After MEM ack: AES dv grant should clear"

    dut._log.info("PASS: rd_txt MEM -> AES smoke test")