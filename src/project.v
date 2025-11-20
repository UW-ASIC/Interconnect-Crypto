/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
  // Shared tri-state bus (Bot databus instances are wired to the same bus)
  wire [7:0] shared_bus_data;
  wire       shared_bus_valid;

  // Simple arbiter test (I'm manually setting which bus is sending and receiving data)
  wire grant_bus_to_A = ui_in[0];
  wire grant_bus_to_B = ui_in[1];

  // Receiving Wires (where each bus output data they received)
  wire [7:0] receive_A;
  wire [7:0] receive_B;

  wire valid_A;
  wire valid_B;

  data_bus_device busA (
      .clk(clk),
      .rst_n(rst_n),

      .send_valid(ui_in[0]),
      .send_data(ui_in[7:0]),
      .send_ready(),

      .recv_valid(valid_A),
      .recv_data(receive_A),

      .bus_grant(grant_bus_to_A),

      .bus_data(shared_bus_data),
      .bus_valid(shared_bus_valid)
  );

  data_bus_device busB (
      .clk(clk),
      .rst_n(rst_n),

      .send_valid(ui_in[1]),
      .send_data(ui_in[7:0]),
      .send_ready(),

      .recv_valid(valid_B),
      .recv_data(receive_B),

      .bus_grant(grant_bus_to_B),

      .bus_data(shared_bus_data),
      .bus_valid(shared_bus_valid)
  );

  // Check up on receive_B, valid_B and valid_A
  assign uo_out = {receive_B[7:2], valid_B, valid_A};
  
  // Defaults for unused inputs and outputs
  assign uio_out = 8'b0;
  assign uio_oe  = 8'b0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, uio_in 1'b0};

endmodule

/*

Essentially how I'm trying to test the databus
1. Set data payload in ui_in[7:2]
2. Allow A to transmit by setting ui_in[0] = 1
3. A drives "shared_bus_data"
4. B receives it and stores in "receive_B"
5. A sees it too since its wired to the same bus and stores it in "receive_A"
6. Do the same but reversed (ui_in[1] = 1)

*/