module ack_bus_arbiter (
    // Resolved open-drain bus (declared as tri1 nets at the top level)
    input  wire       ack_valid_n_bus,   // 0 = at least one module is acking
    input  wire [1:0] ack_id_bus,        // resolved lowest ID on the bus

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
    // Active-high bus-valid
    // assign ack_event = (ack_valid_n_bus == 1'b0) ? 1'b1 : 1'b0;
    assign ack_event = (req_mem | req_sha | req_aes | req_ctrl);

    // Combinational arbitration
    always @* begin
        // defaults
        ack_ready_to_ctrl = 1'b0;
        ack_ready_to_aes  = 1'b0;
        ack_ready_to_sha  = 1'b0;
        ack_ready_to_mem  = 1'b0;
        winner_source_id  = 2'b11; // don't-care if no event

        if (ack_event) begin
            // winner_source_id = ack_id_bus;
            // Grant READY only to the requester whose ID matches the bus
            // case (ack_id_bus)
            //     2'b00 : if (req_mem)  ack_ready_to_mem  = 1'b1;
            //     2'b01 : if (req_sha)  ack_ready_to_sha  = 1'b1;
            //     2'b10 : if (req_aes)  ack_ready_to_aes  = 1'b1;
            //     default : if (req_ctrl) ack_ready_to_ctrl = 1'b1; 
            // endcase
            if (req_mem) begin
                winner_source_id = 2'b00; 
                ack_ready_to_mem = 1'b1;
            end else if (req_sha) begin
                winner_source_id = 2'b01; 
                ack_ready_to_sha = 1'b1;
            end else if (req_aes) begin
                winner_source_id = 2'b10; 
                ack_ready_to_aes = 1'b1;
            end else if (req_ctrl) begin
                winner_source_id = 2'b11; 
                ack_ready_to_ctrl = 1'b1;
            end
        end
    end
    // assign winner_source_id = ack_id_bus;
endmodule
