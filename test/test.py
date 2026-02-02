# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    dut._log.info("Test project behavior")

    # Set the input values you want to test
    dut.ui_in.value = 20
    dut.uio_in.value = 30

    # Wait for one clock cycle to see the output values
    await ClockCycles(dut.clk, 1)

    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
    assert dut.uo_out.value == 50

    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.


#test for the ready signals
@cocotb.test()
async def ready_test(dut):
    
    dut._log_info("Reset")
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10, unit = "us")
    dut.rst_n.value = 1
    dut._log.info("Testing Ready Signals")

    #initially, set all ready values to 0, this means that all the values are not ready
    dut.mem_ready.value = 0
    dut.sha_ready.value = 0
    dut.aes_ready.value = 0
    dut.ctrl_ready.value = 0
    dut._log.info("All infos not set to ready")
    #wait for rising edge and check if the bus is not ready
    await RisingEdge(dut.clk)
    assert dut.bus_ready.value == 0
    dut._log.info("Passed all not ready test")

    #now set the mem to be ready
    dut.mem_ready.value = 1
    dut._log.info("mem is set to ready")
    #wait for rising edge to check
    await RisingEdge(dut.clk)
    assert dut.bus_ready.value == 1

    #reset the mem and set the sha back to ready
    dut.mem_ready.value = 0
    dut.sha_ready.value = 1
    dut._log.info("sha is set to ready")
    #wait for rising edge to check
    await RisingEdge(dut.clk)
    assert dut.bus_ready.value == 1

    #reset the sha and set the aes back to ready
    dut.sha_ready.value = 0
    dut.aes_ready.value = 1
    dut._log.info("aes is set to ready")
    #wait for rising edge to check
    await RisingEdge(dut.clk)
    assert dut.bus_ready.value == 1
    
    #set control to ready and aes back
    dut.ctrl_ready.value = 1
    dut.aes_ready.value = 0
    dut._log.info("ctrl is set to ready")
    #wait for rising edge and check
    await RisingEdge(dut.clk)
    assert dut.bus_ready.value == 1

#test for bus sending data
@cocotb.test()
async def data_transmission_test(dut):
    #reset everything first
    dut._log_info("Reset")
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10, unit = "us")
    dut.rst_n.value = 1
    dut._log.info("Testing Ready Signals")
    
    #we test this module by crafting a destination and crafting a dummy hashed value to send to the module
    dut.READY.value = 1
    dut.ctrl_ready.value = 0
    dut.sha_ready.value = 0
    dut.aes_ready.value = 0
    dut.mem_ready.value = 1
    #now we decide that we want to do a wr_res, say we need to make a dummy address
    dummy_addr = 0x001234
    #now we craft the fake opcode needed for the command/driving
    op_code = 0b10100010
    #crafting the header as per the beats architecture required
    dut.header.value = [dummy_addr >> 16 & 0xFF, dummy_addr >> 8 & 0xFF, dummy_addr >> 0 & 0xFF, op_code]
    #now we set up a test payload
    payload = [0xDE,0xAD,0xBE,0xEF, 0x11,0x22,0x33,0x44]
    await RisingEdge(dut.clk)
    for beats in dut.header.value:
        #send the beats of the data 1 by 1
        dut.ctrl_data = beats
        #set the control valid back to true
        dut.ctrl_valid.value = 1
        #wait for handshaking signals
        while(True):
            await RisingEdge(dut.clk)
            if(dut.ctrl_ready.value):
                break
    dut.ctrl_valid.value = 0
    #send payload data in
    for data in payload:
        dut.aes_data.value = data
        dut.aes_valid.value = 1
        while(True):
            await RisingEdge(dut.clk)
            if(dut.aes_ready.value):
                break
    dut.aes_ready.value = 0

    #check whether the header was captured and matches
    for load in payload:
        await RisingEdge(dut.clk)
        if dut.bus_valid.value and dut.bus_ready.value:
            assert dut.bus_data.value == load
    



