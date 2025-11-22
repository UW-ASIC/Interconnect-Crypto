module ack_bus_arbiter (
    // Requests from modules
    input  wire       req_mem,
    input  wire       req_sha,
    input  wire       req_aes,
    input  wire       req_ctrl,

    // One-hot READY back to modules (grant to winner)
    output reg        ack_ready_to_mem,
    output reg        ack_ready_to_sha,
    output reg        ack_ready_to_aes,
    output reg        ack_ready_to_ctrl,

    // Broadcast winner to everyone
    output reg  [1:0] winner_source_id,

    // 1 when any requester is active
    output wire       ack_event
);

    // Active-high "any request" flag
    assign ack_event = req_mem | req_sha | req_aes | req_ctrl;

    always @* begin
        // defaults
        ack_ready_to_mem  = 1'b0;
        ack_ready_to_sha  = 1'b0;
        ack_ready_to_aes  = 1'b0;
        ack_ready_to_ctrl = 1'b0;
        winner_source_id  = 2'b11;  // don't-care when ack_event == 0

        if (ack_event) begin
            // Highest priority: CTRL
            if (req_ctrl) begin
                ack_ready_to_ctrl = 1'b1;
                winner_source_id  = 2'b11;  // CTRL
            end
            // Next: MEM
            else if (req_mem) begin
                ack_ready_to_mem  = 1'b1;
                winner_source_id  = 2'b00;  // MEM
            end
            // Next: AES
            else if (req_aes) begin
                ack_ready_to_aes  = 1'b1;
                winner_source_id  = 2'b10;  // AES
            end
            // Lowest: SHA
            else if (req_sha) begin
                ack_ready_to_sha  = 1'b1;
                winner_source_id  = 2'b01;  // SHA
            end
        end
    end

endmodule
