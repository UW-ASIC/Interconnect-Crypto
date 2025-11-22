module ack_bus_arbiter (
    // Resolved open-drain bus (declared as tri1 nets at the top level)
    input  wire       ack_valid_n_bus,   // 0 = at least one module is acking
    input  wire [1:0] ack_id_bus,        // resolved lowest ID on the bus (currently unused for priority)

    // Sideband: actual requests (from modules’ latched interfaces)
    input  wire       req_ctrl,
    input  wire       req_aes,
    input  wire       req_sha,
    input  wire       req_mem,

    // One-hot READY back to modules (grant to winner)
    output reg        ack_ready_to_ctrl,
    output reg        ack_ready_to_aes,
    output reg        ack_ready_to_sha,
    output reg        ack_ready_to_mem,

    // Broadcast winner to everyone
    output reg  [1:0] winner_source_id,

    // Convenience mirror of bus-valid in active-high form
    output wire       ack_event            // 1 when any ack is on the bus
);

    // Active-high bus-valid: ack_event is the inverse of ack_valid_n_bus
    // ack_valid_n_bus == 0  <=>  at least one requester is active
    assign ack_event = (ack_valid_n_bus == 1'b0);

    // ----------------------------------------------------------------
    // Static-priority arbitration:
    //   Highest -> lowest: CTRL > MEM > AES > SHA
    //   winner_source_id encoding is unchanged:
    //     2'b00 : MEM
    //     2'b01 : SHA
    //     2'b10 : AES
    //     2'b11 : CTRL
    // ----------------------------------------------------------------
    always @* begin
        // defaults
        ack_ready_to_ctrl = 1'b0;
        ack_ready_to_aes  = 1'b0;
        ack_ready_to_sha  = 1'b0;
        ack_ready_to_mem  = 1'b0;

        // Default "don't care" winner when no event (kept as 2'b11 as before)
        winner_source_id  = 2'b11;

        // Only arbitrate when at least one requester is active on the bus
        if (ack_valid_n_bus == 1'b0) begin
            // Static priority: CTRL > MEM > AES > SHA
            if (req_ctrl) begin
                ack_ready_to_ctrl = 1'b1;
                winner_source_id  = 2'b11; // CTRL
            end else if (req_mem) begin
                ack_ready_to_mem  = 1'b1;
                winner_source_id  = 2'b00; // MEM
            end else if (req_aes) begin
                ack_ready_to_aes  = 1'b1;
                winner_source_id  = 2'b10; // AES
            end else if (req_sha) begin
                ack_ready_to_sha  = 1'b1;
                winner_source_id  = 2'b01; // SHA
            end
            // If ack_valid_n_bus == 0 but none of the req_* are 1, this
            // shouldn't happen given the ack_valid_n_bus generation,
            // and we just fall through with all READY = 0.
        end
    end

endmodule
