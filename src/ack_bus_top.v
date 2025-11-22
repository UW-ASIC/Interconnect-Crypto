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
    output wire       ack_event

    // Debug/monitor (resolved bus)
    // output wire       ack_valid_n_bus_o,
    // output wire [1:0] ack_id_bus_o
);
    // Shared open-drain nets
    wire       ack_valid_n_bus;
    wire [1:0] ack_id_bus;

    // Expose for debug
    // assign ack_valid_n_bus_o = ack_valid_n_bus;
    // assign ack_id_bus_o      = ack_id_bus;

    // Fixed IDs
    wire [1:0] ID_MEM  = 2'b00;
    wire [1:0] ID_SHA  = 2'b01;
    wire [1:0] ID_AES  = 2'b10;
    wire [1:0] ID_CTRL = 2'b11;

    // Open-drain driving: drive 0 on your 0-bits while requesting, else 'z
    assign ack_valid_n_bus = (req_mem | req_sha | req_aes | req_ctrl)  ? 1'b0 : 1'b1;
    
    // // MEM
    // assign ack_id_bus[1]   = (req_mem  && (ID_MEM[1]  == 1'b0)) ? 1'b0 : 1'b1;
    // assign ack_id_bus[0]   = (req_mem  && (ID_MEM[0]  == 1'b0)) ? 1'b0 : 1'b1;
    // // SHA
    // assign ack_id_bus[1]   = (req_sha  && (ID_SHA[1]  == 1'b0)) ? 1'b0 : 1'b1;
    // assign ack_id_bus[0]   = (req_sha  && (ID_SHA[0]  == 1'b0)) ? 1'b0 : 1'b1;
    // // AES
    // assign ack_id_bus[1]   = (req_aes  && (ID_AES[1]  == 1'b0)) ? 1'b0 : 1'b1;
    // assign ack_id_bus[0]   = (req_aes  && (ID_AES[0]  == 1'b0)) ? 1'b0 : 1'b1;
    // // CTRL
    // assign ack_id_bus[1]   = (req_ctrl && (ID_CTRL[1] == 1'b0)) ? 1'b0 : 1'b1;
    // assign ack_id_bus[0]   = (req_ctrl && (ID_CTRL[0] == 1'b0)) ? 1'b0 : 1'b1;

    // ID bit[1] contributions
    wire mem_id1
    wire sha_id1;
    wire aes_id1;
    wire ctrl_id1;

    assign mem_id1  = (ID_MEM [1] == 1'b0 && req_mem ) ? 1'b0 : 1'b1;
    assign sha_id1  = (ID_SHA [1] == 1'b0 && req_sha ) ? 1'b0 : 1'b1;
    assign aes_id1  = (ID_AES [1] == 1'b0 && req_aes ) ? 1'b0 : 1'b1;
    assign ctrl_id1 = (ID_CTRL[1] == 1'b0 && req_ctrl) ? 1'b0 : 1'b1;

    // ID bit[0] contributions
    wire mem_id0;
    wire sha_id0;
    wire aes_id0;
    wire ctrl_id0;

    assign mem_id0  = (ID_MEM [0] == 1'b0 && req_mem ) ? 1'b0 : 1'b1;
    assign sha_id0  = (ID_SHA [0] == 1'b0 && req_sha ) ? 1'b0 : 1'b1;
    assign aes_id0  = (ID_AES [0] == 1'b0 && req_aes ) ? 1'b0 : 1'b1;
    assign ctrl_id0 = (ID_CTRL[0] == 1'b0 && req_ctrl) ? 1'b0 : 1'b1;

    // Resolved ID on the bus (bitwise AND of all contenders' IDs)
    wire [1:0] ack_id_bus;
    assign ack_id_bus[1] = mem_id1 &
                           sha_id1 &
                           aes_id1 &
                           ctrl_id1;

    assign ack_id_bus[0] = mem_id0 &
                           sha_id0 &
                           aes_id0 &
                           ctrl_id0;

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
