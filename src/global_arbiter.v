`default_nettype none

module global_arbiter (
    input wire clk,
    input wire rst_n,

    // mem 

    // mem -> data bus
    input  wire [7:0] data_in_mem,
    input  wire       valid_in_mem,
    output wire       ready_out_mem,

    // data bus -> mem
    output wire [7:0] data_out_mem,
    output wire       valid_out_mem,
    input  wire       ready_in_mem,

    // read grants to mem local data bus interface
    output wire       rdy_rd_grant_mem,
    output wire       dv_rd_grant_mem,

    // mem -> ack bus
    input  wire [1:0] ack_id_in_mem,
    input  wire       ack_valid_in_mem,
    output wire       ack_ready_out_mem,

    // aes

    // aes -> data bus
    input  wire [7:0] data_in_aes,
    input  wire       valid_in_aes,
    output wire       ready_out_aes,

    // data bus -> aes
    output wire [7:0] data_out_aes,
    output wire       valid_out_aes,
    input  wire       ready_in_aes,

    // read grants to aes local data bus interface
    output wire       rdy_rd_grant_aes,
    output wire       dv_rd_grant_aes,

    // aes -> ack bus
    input  wire [1:0] ack_id_in_aes,
    input  wire       ack_valid_in_aes,
    output wire       ack_ready_out_aes,

    // sha

    // sha -> data bus
    input  wire [7:0] data_in_sha,
    input  wire       valid_in_sha,
    output wire       ready_out_sha,

    // data bus -> sha
    output wire [7:0] data_out_sha,
    output wire       valid_out_sha,
    input  wire       ready_in_sha,

    // read grants to sha local data bus interface
    output wire       rdy_rd_grant_sha,
    output wire       dv_rd_grant_sha,

    // sha -> ack bus
    input  wire [1:0] ack_id_in_sha,
    input  wire       ack_valid_in_sha,
    output wire       ack_ready_out_sha,

    // ctrl

    // ctrl -> data bus
    // ctrl owns the bus by default and sends opcode/address bytes
    input  wire [7:0] data_in_ctrl,
    input  wire       valid_in_ctrl,
    output wire       ready_out_ctrl,

    // read grant to ctrl local data bus interface
    // ctrl needs to see ready, but does not need data/valid from data bus
    output wire       rdy_rd_grant_ctrl,

    // ctrl -> ack bus
    input  wire [1:0] ack_id_in_ctrl,
    input  wire       ack_valid_in_ctrl,
    output wire       ack_ready_out_ctrl
);

    // local IDs
    // bit mapping:
    //   mem  = 00 -> bit 0
    //   sha  = 01 -> bit 1
    //   aes  = 10 -> bit 2
    //   ctrl = 11 -> bit 3

    localparam [1:0] MEM_ID  = 2'b00;
    localparam [1:0] SHA_ID  = 2'b01;
    localparam [1:0] AES_ID  = 2'b10;
    localparam [1:0] CTRL_ID = 2'b11;


    // internal data bus wires

    wire [7:0] data_on_bus;
    wire       valid_on_bus;
    wire       rdy_to_owner;
    wire [1:0] data_sel;

    wire [3:0] rdy_rd_grant;
    wire [3:0] dv_rd_grant;


    // internal ack bus wires
    // ack arbiter outputs active-low valid, data_bus_ctrl wants active-high valid

    wire       ack_valid_n;
    wire       valid_on_ack;
    wire       ready_on_ack;
    wire [1:0] id_on_ack;

    assign valid_on_ack = ~ack_valid_n;
    assign ready_on_ack = 1'b1;          // ack bus is always ready in this version
    assign id_on_ack    = winner_source_id;

    wire [1:0] winner_source_id;

    // data bus owner mux
    // data_sel chooses who is currently driving data_on_bus/valid_on_bus

    assign data_on_bus = (data_sel == MEM_ID)  ? data_in_mem  : (data_sel == SHA_ID)  ? data_in_sha  : (data_sel == AES_ID)  ? data_in_aes  :
    (data_sel == CTRL_ID) ? data_in_ctrl : 8'h00;

    assign valid_on_bus = (data_sel == MEM_ID)  ? valid_in_mem  : (data_sel == SHA_ID)  ? valid_in_sha  : (data_sel == AES_ID)  ? valid_in_aes  :
    (data_sel == CTRL_ID) ? valid_in_ctrl :1'b0;

    // data bus outputs to modules
    // data is broadcast, valid is gated by dv_rd_grant

    assign data_out_mem = data_on_bus;
    assign data_out_sha = data_on_bus;
    assign data_out_aes = data_on_bus;

    assign valid_out_mem = dv_rd_grant[0] ? valid_on_bus : 1'b0;
    assign valid_out_sha = dv_rd_grant[1] ? valid_on_bus : 1'b0;
    assign valid_out_aes = dv_rd_grant[2] ? valid_on_bus : 1'b0;

    // ctrl does not receive data/valid from data bus, so no data_out_ctrl/valid_out_ctrl

    // ready outputs to modules
    // rdy_to_owner is broadcast only to whoever has ready-read grant

    assign ready_out_mem  = rdy_rd_grant[0] ? rdy_to_owner : 1'b0;
    assign ready_out_sha  = rdy_rd_grant[1] ? rdy_to_owner : 1'b0;
    assign ready_out_aes  = rdy_rd_grant[2] ? rdy_to_owner : 1'b0;
    assign ready_out_ctrl = rdy_rd_grant[3] ? rdy_to_owner : 1'b0;

    // expose grant bits

    assign rdy_rd_grant_mem  = rdy_rd_grant[0];
    assign rdy_rd_grant_sha  = rdy_rd_grant[1];
    assign rdy_rd_grant_aes  = rdy_rd_grant[2];
    assign rdy_rd_grant_ctrl = rdy_rd_grant[3];

    assign dv_rd_grant_mem   = dv_rd_grant[0];
    assign dv_rd_grant_sha   = dv_rd_grant[1];
    assign dv_rd_grant_aes   = dv_rd_grant[2];

    // data bus controller
    // controls data_sel, read grants, and ready-to-current-owner

    data_bus_ctrl u_data_bus_ctrl (
        .clk          (clk),
        .rst_n        (rst_n),

        // current data bus
        .data_on_bus  (data_on_bus),
        .valid_on_bus (valid_on_bus),

        // ready from destination modules
        .rdy_mem      (ready_in_mem),
        .rdy_aes      (ready_in_aes),
        .rdy_sha      (ready_in_sha),

        // ack bus handshake
        .id_on_ack    (id_on_ack),
        .ready_on_ack (ready_on_ack),
        .valid_on_ack (valid_on_ack),

        // grants and bus owner select
        .rdy_rd_grant (rdy_rd_grant),
        .dv_rd_grant  (dv_rd_grant),
        .data_sel     (data_sel),

        // ready back to current owner
        .rdy_to_owner (rdy_to_owner)
    );


    // ack bus arbiter
    // chooses one ack source and sends winner ID to data_bus_ctrl

    ack_bus_arbiter u_ack_bus_arbiter (
        // ack valid requests from modules
        .ack_valid_from_ctrl (ack_valid_in_ctrl),
        .ack_valid_from_aes  (ack_valid_in_aes),
        .ack_valid_from_sha  (ack_valid_in_sha),
        .ack_valid_from_mem  (ack_valid_in_mem),

        // ready back to winning module
        .ack_ready_to_ctrl   (ack_ready_out_ctrl),
        .ack_ready_to_aes    (ack_ready_out_aes),
        .ack_ready_to_sha    (ack_ready_out_sha),
        .ack_ready_to_mem    (ack_ready_out_mem),

        // shared ack bus result
        .ack_valid_n         (ack_valid_n),
        .winner_source_id    (winner_source_id)
    );

endmodule