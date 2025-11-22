// Simple top-level wrapper around the ack bus arbiter.
// Requests:  req_* are active-high requests from MEM, SHA, AES, CTRL.
// Grants:    ack_ready_to_* are one-hot grants back to the requesters.
// Winner:    winner_source_id encodes the winning source:
//              2'b00 : MEM
//              2'b01 : SHA
//              2'b10 : AES
//              2'b11 : CTRL
// Event:     ack_event is 1 when any request is active.
//
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
);

    // Purely combinational arbiter implementing static priority:
    //   MEM > SHA > AES > CTRL
    ack_bus_arbiter u_ack_arb (
        .req_mem          (req_mem),
        .req_sha          (req_sha),
        .req_aes          (req_aes),
        .req_ctrl         (req_ctrl),

        .ack_ready_to_mem (ack_ready_to_mem),
        .ack_ready_to_sha (ack_ready_to_sha),
        .ack_ready_to_aes (ack_ready_to_aes),
        .ack_ready_to_ctrl(ack_ready_to_ctrl),

        .winner_source_id (winner_source_id),
        .ack_event        (ack_event)
    );

endmodule
