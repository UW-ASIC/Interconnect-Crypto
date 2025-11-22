module ack_bus_top (
    // Requests from modules
    input  wire       req_mem,
    input  wire       req_sha,
    input  wire       req_aes,
    input  wire       req_ctrl,

    // READY grants back (one-hot)
    output wire       ack_ready_to_mem,
    output wire       ack_ready_to_sha,
    output wire       ack_ready_to_aes,
    output wire       ack_ready_to_ctrl,

    // Broadcast winner + event
    output wire [1:0] winner_source_id,
    output wire       ack_event,

    // Debug/monitor (resolved bus)
    output wire       ack_valid_n_bus_o,
    output wire [1:0] ack_id_bus_o
);
    // Shared open-drain nets
    tri1       ack_valid_n_bus;
    tri1 [1:0] ack_id_bus;

    // Expose for debug
    assign ack_valid_n_bus_o = ack_valid_n_bus;
    assign ack_id_bus_o      = ack_id_bus;

    // Fixed IDs
    wire [1:0] ID_MEM  = 2'b00;
    wire [1:0] ID_SHA  = 2'b01;
    wire [1:0] ID_AES  = 2'b10;
    wire [1:0] ID_CTRL = 2'b11;

    // Open-drain driving: drive 0 on your 0-bits while requesting, else 'z
    // MEM
    assign ack_valid_n_bus = req_mem  ? 1'b0 : 1'bz;
    assign ack_id_bus[1]   = (req_mem  && (ID_MEM[1]  == 1'b0)) ? 1'b0 : 1'bz;
    assign ack_id_bus[0]   = (req_mem  && (ID_MEM[0]  == 1'b0)) ? 1'b0 : 1'bz;
    // SHA
    assign ack_valid_n_bus = req_sha  ? 1'b0 : 1'bz;
    assign ack_id_bus[1]   = (req_sha  && (ID_SHA[1]  == 1'b0)) ? 1'b0 : 1'bz;
    assign ack_id_bus[0]   = (req_sha  && (ID_SHA[0]  == 1'b0)) ? 1'b0 : 1'bz;
    // AES
    assign ack_valid_n_bus = req_aes  ? 1'b0 : 1'bz;
    assign ack_id_bus[1]   = (req_aes  && (ID_AES[1]  == 1'b0)) ? 1'b0 : 1'bz;
    assign ack_id_bus[0]   = (req_aes  && (ID_AES[0]  == 1'b0)) ? 1'b0 : 1'bz;
    // CTRL
    assign ack_valid_n_bus = req_ctrl ? 1'b0 : 1'bz;
    assign ack_id_bus[1]   = (req_ctrl && (ID_CTRL[1] == 1'b0)) ? 1'b0 : 1'bz;
    assign ack_id_bus[0]   = (req_ctrl && (ID_CTRL[0] == 1'b0)) ? 1'b0 : 1'bz;

    // Arbiter reads the bus & grants one-hot to the winner
    ack_bus_arbiter u_ack_arb (
        .ack_valid_n_bus     (ack_valid_n_bus),
        .ack_id_bus          (ack_id_bus),
        .req_mem             (req_mem),
        .req_sha             (req_sha),
        .req_aes             (req_aes),
        .req_ctrl            (req_ctrl),
        .ack_ready_to_mem    (ack_ready_to_mem),
        .ack_ready_to_sha    (ack_ready_to_sha),
        .ack_ready_to_aes    (ack_ready_to_aes),
        .ack_ready_to_ctrl   (ack_ready_to_ctrl),
        .winner_source_id    (winner_source_id),
        .ack_event           (ack_event)
    );
endmodule
