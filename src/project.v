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

  // All output pins must be assigned. If not used, assign to 0.
  //assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
  assign uo_out[7] = 0;
  assign uio_out = 0;
  assign uio_oe  = 0;

  wire       ack_valid;
  wire [1:0] ack_id_bus;

  ack_bus_top ack_bus_top_inst (
    .req_mem (ui_in[0]),
    .req_sha (ui_in[1]),
    .req_aes (ui_in[2]),
    .req_ctrl (ui_in[3]),
    .ack_ready_to_mem (uo_out[0]),
    .ack_ready_to_sha (uo_out[1]),
    .ack_ready_to_aes (uo_out[2]),
    .ack_ready_to_ctrl (uo_out[3]),
    .winner_source_id (uo_out[5:4]),
    .ack_event (uo_out[6]),
    .ack_valid_n_bus_o (ack_valid),
    .ack_id_bus_o (ack_id_bus)
  );

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, ui_in[7:4], uio_in, 1'b0};

endmodule
