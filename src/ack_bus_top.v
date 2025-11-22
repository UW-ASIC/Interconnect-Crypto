module ack_bus_top (
    input  wire       req_mem,
    input  wire       req_sha,
    input  wire       req_aes,
    input  wire       req_ctrl,
    output wire       ack_ready_to_mem,
    output wire       ack_ready_to_sha,
    output wire       ack_ready_to_aes,
    output wire       ack_ready_to_ctrl,
    output wire [1:0] winner_source_id,
    output wire       ack_event
);

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
