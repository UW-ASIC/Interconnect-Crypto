// /*List of Source IDs
//   MEM: 00; SHA: 01; AES: 10; CTRL: 11
// */
// module ack_bus_arbiter (
//     // inputs from modules
//     // "1" indicates that source module succeeds in sending its last bit, and it asserts its ack signal
//     input wire ack_valid_from_ctrl,
//     input wire ack_valid_from_aes,
//     input wire ack_valid_from_sha,
//     input wire ack_valid_from_mem,
//     // input wire [7:0] module_source_ids,        // the id of the source modules sending ack, 2 bits/module, {2'b11, 2'b10, 2'b01, 2'b00}
    
//     // output to modules
//     // send the arbitration result to the module, "1" indicates that ack_bus is ready, the module can stop asserting ack
//     output reg ack_ready_to_ctrl,
//     output reg ack_ready_to_aes,
//     output reg ack_ready_to_sha,
//     output reg ack_ready_to_mem,

//     // ack bus wires (open drain)
//     output reg       ack_valid_n,              // active-low: 0 -> some module is asserting its ack signal in this cycle
//     output reg [1:0] winner_source_id         // source ID of the winner of the arbitration
// );

// always @(*) begin 
//     // Check the ack_valid signal for all modules to see if they are asserting ack signal
//     // Choose the module with highest priority as the winner
//     // The following is implemented with priority "CTRL > AES > SHA > MEM" in mind, but can be changed later.

//     //default values
//     {ack_ready_to_ctrl, ack_ready_to_aes, ack_ready_to_sha, ack_ready_to_mem} = 4'b0;
//     ack_valid_n = 1'b1;
//     winner_source_id = 2'b11;   //CTRL has default ownship of the bus

//     if (ack_ready_to_ctrl == 1'b1) begin
//       //CTRL module is asserting ack
//       {ack_ready_to_ctrl, ack_ready_to_aes, ack_ready_to_sha, ack_ready_to_mem} = 4'b1000;
//       ack_valid_n = 1'b0;
//       winner_source_id = 2'b11;
//     end

//     else if (ack_ready_to_aes == 1'b1) begin
//       //AES module is asserting ack
//       {ack_ready_to_ctrl, ack_ready_to_aes, ack_ready_to_sha, ack_ready_to_mem} = 4'b0100;
//       ack_valid_n = 1'b0;
//       winner_source_id = 2'b10;
//     end

//     else if (ack_ready_to_sha == 1'b1) begin
//       //SHA module is asserting ack
//       {ack_ready_to_ctrl, ack_ready_to_aes, ack_ready_to_sha, ack_ready_to_mem} = 4'b0010;
//       ack_valid_n = 1'b0;
//       winner_source_id = 2'b01;
//     end

//     else if (ack_ready_to_mem == 1'b1) begin
//       //MEM module is asserting ack
//       {ack_ready_to_ctrl, ack_ready_to_aes, ack_ready_to_sha, ack_ready_to_mem} = 4'b0001;
//       ack_valid_n = 1'b0;
//       winner_source_id = 2'b00;
//     end
// end

// endmodule


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
    assign ack_event = (ack_valid_n_bus == 1'b0);

    // Combinational arbitration
    always @* begin
        // defaults
        ack_ready_to_ctrl = 1'b0;
        ack_ready_to_aes  = 1'b0;
        ack_ready_to_sha  = 1'b0;
        ack_ready_to_mem  = 1'b0;
        winner_source_id  = 2'b11; // don't-care if no event

        if (ack_event) begin
            winner_source_id = ack_id_bus;

            // Grant READY only to the requester whose ID matches the bus
            case (ack_id_bus)
              2'b00 : if (req_mem)  ack_ready_to_mem  = 1'b1;
              2'b01 : if (req_sha)  ack_ready_to_sha  = 1'b1;
              2'b10 : if (req_aes)  ack_ready_to_aes  = 1'b1;
              default : if (req_ctrl) ack_ready_to_ctrl = 1'b1; 
            endcase
        end
    end
endmodule