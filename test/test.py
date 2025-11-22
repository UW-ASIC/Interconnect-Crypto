# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
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


@cocotb.test()
async def reset_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut._log.info("Test project behavior")


    # Outputs (need to check these)
    RECEIVE_DATA = dut.uo_out.value

    RECEIVE_VALIDA = dut.uio_out.value[0]
    RECEIVE_VALIDB = dut.uio_out.value[1]
    RECEIVE_VALIDCTRL = dut.uio_out.value[2]

    SEND_READYA = dut.uio_out.value[3]
    SEND_READYB = dut.uio_out.value[4]
    SEND_READYCTRL = dut.uio_out.value[5]
    
    # Check reset outputs
    assert SEND_READYA.value == 0
    assert SEND_READYB.value == 0
    assert SEND_READYCTRL.value == 0
    
    assert RECEIVE_VALIDA.value == 0
    assert RECEIVE_VALIDB.value == 0
    assert RECEIVE_VALIDCTRL.value == 0
    
    assert RECEIVE_DATA.value == 0


    # Set the input values you want to test
    # dut.ui_in.value = 20
    # dut.uio_in.value = 30

    # Wait for one clock cycle to see the output values
    # await ClockCycles(dut.clk, 1)

    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
    # assert dut.uo_out.value == 50

    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.
    
@cocotb.test()
async def test_reset(dut):
    # Proc low for reset signal
    dut.rst_n.value = 0
    await Timer(10, units="ns")
     
    # Check values
    assert RECEIVE_VALIDA == 0
    assert RECEIVE_VALIDB == 0
    assert RECEIVE_VALIDCTRL == 0

    assert SEND_READYA == 0
    assert SEND_READYB == 0
    assert SEND_READYCTRL == 0
    
    BUS_OUTPUT = BUS_CTRL
    assert RECEIVE_DATA == 0b00000000
    
    dut._log.info("Reset Test Passed")
    
@cocotb.test()


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


