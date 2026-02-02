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




