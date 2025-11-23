# SPDX-FileCopyrightText: Â© 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb.types import Logic
from cocotb.types import LogicArray
from cocotb.triggers import RisingEdge, FallingEdge
from cocotb.triggers import Timer

####################
# GLOBAL VARIABLES #
####################

RISING = 1
FALLING = 0

BUS_A = 0b01
BUS_B = 0b00
BUS_CTRL = 0b11  

"""
# Inputs (You can control)
SEND_VALIDA = dut.uio_in.value[0]
SEND_VALIDB = dut.uio_in.value[1]
SEND_VALIDCTRL = dut.uio_in.value[2]
ACK = dut.uio_in.value[3]

SEND_DATA = dut.ui_in[7:0]

BUS_OUTPUT = dut.uio_in.value[6:4] # 11 = control, 00 = B, 01 = A

BUS_A = 0b01
BUS_B = 0b00
BUS_CTRL = 0b11  
"""

"""
# Outputs
RECEIVE_DATA = dut.uo_out.value

RECEIVE_VALIDA = dut.uio_out.value[0]
RECEIVE_VALIDB = dut.uio_out.value[1]
RECEIVE_VALIDCTRL = dut.uio_out.value[2]

SEND_READYA = dut.uio_out.value[3]
SEND_READYB = dut.uio_out.value[4]
SEND_READYCTRL = dut.uio_out.value[5]
"""




"""
TESTS:
1) Reset: make sure all outputs are correct

2) The expected instruction sequence:
    - Cycle 1: Control asserts send_valid, and sends the first packet (send_data)
        --> ALL modules should receive first packet 
    - Cycle 2: Control sends address 1 --> src/dest should be reading those
    - Cycle 3: Control sends address 2 --> src/dest should be reading those
    - Cycle 4: Control sends address 3 --> src/dest should be reading those
    
    - Cycle 5: src gets ownership of bus. It sends some random packet AB. dest should be able to read it
    - Cycle 6: src gets ownership of bus. It sends some random packet CD. dest should be able to read it
    - Cycle 7: src gets ownership of bus. It sends some random packet EF. dest should be able to read it
    - Cycle 8: src sends an ack. src gets ownership of bus. It sends some random packet 00. dest should be able to read it
    
    - Cycle 9: all output values are reset. Control has ownership of bus again 
"""


"""
DUT SIGNALS:
    - input  wire [7:0] ui_in 
    - input  wire [7:0] uio_in (unused)
    - input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    - input  wire       clk,      // clock
    - input  wire       rst_n     // reset_n - low to reset
    
    - output wire [7:0] uo_out
    - output wire [7:0] uio_out
    - output wire [7:0] uio_oe,

"""


# @cocotb.test()
# async def reset_project(dut):
#     dut._log.info("Start")

#     # Set the clock period to 10 us (100 KHz)
#     clock = Clock(dut.clk, 10, units="us")
#     cocotb.start_soon(clock.start())

#     # Reset
#     dut._log.info("Asserting Reset")
#     dut.ena.value = 1
#     dut.ui_in.value = 0
#     dut.uio_in.value = 0

#     dut.rst_n.value = 0
#     await ClockCycles(dut.clk, 10)

#     # Outputs (need to check these)
#     RECEIVE_DATA = dut.uo_out.value

#     RECEIVE_VALIDA = dut.uio_out.value[0]
#     RECEIVE_VALIDB = dut.uio_out.value[1]
#     RECEIVE_VALIDCTRL = dut.uio_out.value[2]

#     SEND_READYA = int(dut.uio_out.value[3])
#     SEND_READYB = dut.uio_out.value[4]
#     SEND_READYCTRL = dut.uio_out.value[5]
    
#     # Check reset outputs
#     assert SEND_READYA == 1
#     assert SEND_READYB == 1
#     assert SEND_READYCTRL == 1
    
#     assert RECEIVE_VALIDA == 0
#     assert RECEIVE_VALIDB == 0
#     assert RECEIVE_VALIDCTRL == 0
    
#     assert RECEIVE_DATA == 0

#     dut.rst_n.value = 1
#     await ClockCycles(dut.clk, 10)
#     dut._log.info("Test project behavior")


    # Set the input values you want to test
    # dut.ui_in.value = 20
    # dut.uio_in.value = 30

    # Wait for one clock cycle to see the output values
    # await ClockCycles(dut.clk, 1)

    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
    # assert dut.uo_out.value == 50

    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values
    
    

@cocotb.test()
async def test_multi_a_b_transactions(dut):
    """Multiple A→B transactions, checking same-cycle recv_valid and send_ready."""
    dut._log.info("Start")

    # # Set the clock period to 10 ns (100 KHz)
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    # cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # Reset DUT
    dut.rst_n.value = 0
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    await RisingEdge(dut.clk)

    # Control sets ownership (src=A, dest=B)
    dut.ui_in.value = 0b01000100
    # dut.uio_in.value = 0b00010100  # control send_valid --> read A
    dut.uio_in.value = 0b00000100  # control send_valid --> read B
    # dut.uio_in.value = 0b00010100  # control send_valid
    
    print("CT AM ASSERTING SEND_VALID NOW")
    await RisingEdge(dut.clk)
    
    
    # Check initial outputs
    assert dut.uio_out.value[5] == 1, f"Control send_ready should be high, instead its {dut.uio_out.value[5]}"
    assert dut.uio_out.value[0] == 1, "A recv_valid should be high"
    assert dut.uio_out.value[1] == 1, "B recv_valid should be high"

    # Send 3 addresses     
    dut.ui_in.value = 0xAB
    await RisingEdge(dut.clk)
    dut.ui_in.value = 0xCD
    await RisingEdge(dut.clk)
    dut.ui_in.value = 0xEF
    await RisingEdge(dut.clk)
    
    # Multiple A→B transactions
    data_seq = [0x12, 0x34, 0x56, 0x78]
    for val in data_seq:
        dut.ui_in.value = val
        dut.uio_in.value = 0b0001  # A send_valid
        await RisingEdge(dut.clk)
        # Check sequential and combinational outputs
        assert dut.uio_out.value[3] == 1, "A send_ready should be high"
        assert dut.uio_out.value[1] == 1, "B recv_valid should be high"
        assert int(dut.uo_out.value) == val, f"B should receive {val:#02x}"

    # Assert ack
    dut.uio_in.value = 0b00001000
    await RisingEdge(dut.clk)

    # Verify all outputs reset
    for idx in [0,1,2]:
        assert dut.uio_out.value[idx] == 0, f"recv_valid[{idx}] should be 0 after ack"
    for idx in [3,4,5]:
        assert dut.uio_out.value[idx] == 1, f"send_ready[{idx}] should be 0 after ack"

    dut._log.info("Multi A→B transaction test passed")

