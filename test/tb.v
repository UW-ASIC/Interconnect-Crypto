`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

  // Dump the signals to a VCD file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end

  // Wire up the inputs and outputs:
  // reg clk;
  // reg rst_n;
  // reg ena;
  // reg [7:0] ui_in;
  // reg [7:0] uio_in;
  // wire [7:0] uo_out;
  // wire [7:0] uio_out;
  // wire [7:0] uio_oe;
  wire req_mem;
  wire req_sha;
  wire req_aes;
  wire req_ctrl;

  wire ack_ready_to_mem;
  wire ack_ready_to_sha;
  wire ack_ready_to_aes;
  wire ack_ready_to_ctrl;

  wire [1:0] winner_source_id;
  wire ack_event;

  wire ack_valid_n_bus_o;
  wire [1:0] ack_id_bus_o;

`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  // Replace tt_um_example with your module name:
  tt_um_ack_bus_top user_project (

      // Include power ports for the Gate Level test:
`ifdef GL_TEST
      .VPWR(VPWR),
      .VGND(VGND),
`endif

      // .ui_in  (ui_in),    // Dedicated inputs
      // .uo_out (uo_out),   // Dedicated outputs
      // .uio_in (uio_in),   // IOs: Input path
      // .uio_out(uio_out),  // IOs: Output path
      // .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      // .ena    (ena),      // enable - goes high when design is selected
      // .clk    (clk),      // clock
      // .rst_n  (rst_n)     // not reset
      .req_mem (req_mem),
      .req_sha (req_sha),
      .req_aes (req_aes),
      .req_ctrl (req_ctrl),
      .ack_ready_to_mem (ack_ready_to_mem),
      .ack_ready_to_sha (ack_ready_to_sha),
      .ack_ready_to_aes (ack_ready_to_aes),
      .ack_ready_to_ctrl (ack_ready_to_ctrl),
      .winner_source_id (winner_source_id),
      .ack_event (ack_event),
      .ack_valid_n_bus_o (ack_valid_n_bus_o),
      .ack_id_bus_o (ack_id_bus_o)
  );

endmodule
