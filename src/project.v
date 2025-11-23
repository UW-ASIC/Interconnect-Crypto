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

  wire send_readyA;
  wire send_readyB;
  wire send_readyCTRL;

  wire recv_validA;
  wire recv_validB;
  wire recv_validCTRL;

  wire [7:0] recv_dataA;
  wire [7:0] recv_dataB;
  wire [7:0] recv_dataCTRL;

  wire ACK = uio_in[3];

  data_bus busA (
      .clk(clk),
      .rst_n(rst_n),

      .send_valid(uio_in[0]), // input
      .send_data(ui_in[7:0]), // input
      .send_ready(send_readyA),
      .ack(ACK), // input

      .source_id(2'b01), // SHA Id

      .recv_valid(recv_validA),
      .recv_data(recv_dataA),

      .bus_data(shared_bus_data),
      .bus_valid(shared_bus_valid)
  );

  data_bus busB (
      .clk(clk),
      .rst_n(rst_n),

      .send_valid(uio_in[1]), // input
      .send_data(ui_in[7:0]), // input
      .send_ready(send_readyB),
      .ack(ACK), // input

      .recv_valid(recv_validB),
      .recv_data(recv_dataB),

      .source_id(2'b00), // input

      .bus_data(shared_bus_data),
      .bus_valid(shared_bus_valid)
  );

  data_bus control ( // Control 
      .clk(clk),
      .rst_n(rst_n),

      .send_valid(uio_in[2]),
      .send_data(ui_in[7:0]),
      .send_ready(send_readyCTRL),
      .ack(ACK),

      .source_id(2'b11),

      .recv_valid(recv_validCTRL),
      .recv_data(recv_dataCTRL),

      .bus_data(shared_bus_data),
      .bus_valid(shared_bus_valid)

    );


  assign uo_out = (uio_in[5:4] == 2'b01) ? recv_dataA :
                  (uio_in[5:4] == 2'b00) ? recv_dataB :
                  recv_dataCTRL;

  assign uio_out[0] = recv_validA;
  assign uio_out[1] = recv_validB;
  assign uio_out[2] = recv_validCTRL;

  assign uio_out[3] = send_readyA;
  assign uio_out[4] = send_readyB;
  assign uio_out[5] = send_readyCTRL;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, 1'b0};
  assign uio_out[7:6] = 2'b00; 
  assign uio_oe       = 8'b0;  // all pins inputs

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