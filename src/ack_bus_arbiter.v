module ack_bus_arbiter (
    // Requests from modules
    input  wire       req_mem,
    input  wire       req_sha,
    input  wire       req_aes,
    input  wire       req_ctrl,
    output reg        ack_ready_to_mem,
    output reg        ack_ready_to_sha,
    output reg        ack_ready_to_aes,
    output reg        ack_ready_to_ctrl,
    output reg  [1:0] winner_source_id,
    output wire       ack_event
);

    assign ack_event = req_mem | req_sha | req_aes | req_ctrl;
    always @* begin
        // defaults
        ack_ready_to_mem  = 1'b0;
        ack_ready_to_sha  = 1'b0;
        ack_ready_to_aes  = 1'b0;
        ack_ready_to_ctrl = 1'b0;
        winner_source_id  = 2'b11;  // don't-care when ack_event == 0

        if (ack_event) begin
            // Highest priority: MEM
            if (req_mem) begin
                ack_ready_to_mem  = 1'b1;
                winner_source_id  = 2'b00;  // MEM
            end else if (req_sha) begin
                ack_ready_to_sha  = 1'b1;
                winner_source_id  = 2'b01;  // SHA
            end else if (req_aes) begin
                ack_ready_to_aes  = 1'b1;
                winner_source_id  = 2'b10;  // AES
            end else if (req_ctrl) begin
                ack_ready_to_ctrl = 1'b1;
                winner_source_id  = 2'b11;  // CTRL
            end
            
        end
    end

endmodule
