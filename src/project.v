/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */


// wire by ChatGPT
`default_nettype none

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // ============================================================
    // TinyTapeout quick smoke-test pin mapping
    // ============================================================
    //
    // ui_in[7:0]  = test byte driven by CTRL and MEM
    //
    // uio_in[0]   = valid_in_ctrl
    // uio_in[1]   = valid_in_mem
    // uio_in[2]   = ready_in_mem
    // uio_in[3]   = ready_in_aes
    // uio_in[4]   = ready_in_sha
    // uio_in[5]   = ack_valid_in_mem
    // uio_in[6]   = ack_valid_in_aes
    // uio_in[7]   = ack_valid_in_sha
    //
    // uo_out[0]   = ready_out_ctrl
    // uo_out[1]   = ready_out_mem
    // uo_out[2]   = ready_out_aes
    // uo_out[3]   = ready_out_sha
    // uo_out[4]   = dv_rd_grant_mem
    // uo_out[5]   = dv_rd_grant_aes
    // uo_out[6]   = dv_rd_grant_sha
    // uo_out[7]   = ack_ready_out_mem
    // ============================================================

    wire [7:0] test_data_byte;
    assign test_data_byte = ui_in;

    wire valid_in_ctrl;
    wire valid_in_mem;

    wire ready_in_mem;
    wire ready_in_aes;
    wire ready_in_sha;

    wire ack_valid_in_mem;
    wire ack_valid_in_aes;
    wire ack_valid_in_sha;

    assign valid_in_ctrl    = uio_in[0];
    assign valid_in_mem     = uio_in[1];

    assign ready_in_mem     = uio_in[2];
    assign ready_in_aes     = uio_in[3];
    assign ready_in_sha     = uio_in[4];

    assign ack_valid_in_mem = uio_in[5];
    assign ack_valid_in_aes = uio_in[6];
    assign ack_valid_in_sha = uio_in[7];

    // uio pins are inputs only for this smoke-test wrapper
    assign uio_oe  = 8'b0000_0000;
    assign uio_out = 8'b0000_0000;


    // ============================================================
    // Wires from interconnect
    // ============================================================

    wire ready_out_mem;
    wire ready_out_aes;
    wire ready_out_sha;
    wire ready_out_ctrl;

    wire [7:0] data_out_mem;
    wire [7:0] data_out_aes;
    wire [7:0] data_out_sha;

    wire valid_out_mem;
    wire valid_out_aes;
    wire valid_out_sha;

    wire rdy_rd_grant_mem;
    wire rdy_rd_grant_aes;
    wire rdy_rd_grant_sha;
    wire rdy_rd_grant_ctrl;

    wire dv_rd_grant_mem;
    wire dv_rd_grant_aes;
    wire dv_rd_grant_sha;

    wire ack_ready_out_mem;
    wire ack_ready_out_aes;
    wire ack_ready_out_sha;
    wire ack_ready_out_ctrl;

    wire[2:0] ack_bus_out_ctrl;

    // ============================================================
    // Debug outputs
    // ============================================================

    assign uo_out[0] = ready_out_ctrl;
    assign uo_out[1] = ready_out_mem;
    assign uo_out[2] = ready_out_aes;
    assign uo_out[3] = ready_out_sha;

    assign uo_out[4] = dv_rd_grant_mem;
    assign uo_out[5] = dv_rd_grant_aes;
    assign uo_out[6] = dv_rd_grant_sha;

    assign uo_out[7] = ack_ready_out_mem;


    // ============================================================
    // Interconnect
    // ============================================================

    interconnect_top u_interconnect (
        .clk   (clk),
        .rst_n (rst_n),

        // ========================================================
        // MEM
        // ========================================================

        // mem -> data bus
        .data_in_mem   (test_data_byte),
        .valid_in_mem  (valid_in_mem),
        .ready_out_mem (ready_out_mem),

        // data bus -> mem
        .data_out_mem  (data_out_mem),
        .valid_out_mem (valid_out_mem),
        .ready_in_mem  (ready_in_mem),

        // grants
        .rdy_rd_grant_mem (rdy_rd_grant_mem),
        .dv_rd_grant_mem  (dv_rd_grant_mem),

        // mem -> ack bus
        .ack_id_in_mem     (2'b00),
        .ack_valid_in_mem  (ack_valid_in_mem),
        .ack_ready_out_mem (ack_ready_out_mem),


        // ========================================================
        // AES
        // ========================================================

        // aes -> data bus
        // AES does not drive data in this lazy smoke test
        .data_in_aes   (8'h00),
        .valid_in_aes  (1'b0),
        .ready_out_aes (ready_out_aes),

        // data bus -> aes
        .data_out_aes  (data_out_aes),
        .valid_out_aes (valid_out_aes),
        .ready_in_aes  (ready_in_aes),

        // grants
        .rdy_rd_grant_aes (rdy_rd_grant_aes),
        .dv_rd_grant_aes  (dv_rd_grant_aes),

        // aes -> ack bus
        .ack_id_in_aes     (2'b10),
        .ack_valid_in_aes  (ack_valid_in_aes),
        .ack_ready_out_aes (ack_ready_out_aes),


        // ========================================================
        // SHA
        // ========================================================

        // sha -> data bus
        // SHA does not drive data in this lazy smoke test
        .data_in_sha   (8'h00),
        .valid_in_sha  (1'b0),
        .ready_out_sha (ready_out_sha),

        // data bus -> sha
        .data_out_sha  (data_out_sha),
        .valid_out_sha (valid_out_sha),
        .ready_in_sha  (ready_in_sha),

        // grants
        .rdy_rd_grant_sha (rdy_rd_grant_sha),
        .dv_rd_grant_sha  (dv_rd_grant_sha),

        // sha -> ack bus
        .ack_id_in_sha     (2'b01),
        .ack_valid_in_sha  (ack_valid_in_sha),
        .ack_ready_out_sha (ack_ready_out_sha),


        // ========================================================
        // CTRL
        // ========================================================

        // ctrl -> data bus
        .data_in_ctrl   (test_data_byte),
        .valid_in_ctrl  (valid_in_ctrl),
        .ready_out_ctrl (ready_out_ctrl),

        // ctrl ready-read grant
        .rdy_rd_grant_ctrl (rdy_rd_grant_ctrl),

        // ctrl does not write ack in this smoke test
        .ack_id_in_ctrl     (2'b11),
        .ack_valid_in_ctrl  (1'b0),
        .ack_ready_out_ctrl (ack_ready_out_ctrl),

        .ack_out_ctrl(ack_bus_out_ctrl)
    );


    // ============================================================
    // Unused signals
    // ============================================================

    wire _unused;
    assign _unused = ^{
        ena,

        data_out_mem,
        data_out_aes,
        data_out_sha,

        valid_out_mem,
        valid_out_aes,
        valid_out_sha,

        rdy_rd_grant_mem,
        rdy_rd_grant_aes,
        rdy_rd_grant_sha,
        rdy_rd_grant_ctrl,

        ack_ready_out_aes,
        ack_ready_out_sha,
        ack_ready_out_ctrl
    };

endmodule