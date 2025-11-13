/*List of Source IDs
  MEM: 00; SHA: 01; AES: 10; CTRL: 11
*/
module ack_bus_arbiter (
    // inputs from modules
    input wire [3:0] ack_valid_from_modules,   // source module succeeds in sending its last bit, and it asserts ack signal
    input wire [7:0] module_source_ids,        // the id of the source modules sending ack, 2 bits/module
    
    // output to modules
    output reg [3:0] ack_ready_to_module      // send the arbitration result to the module (one hot)

    // ack bus wires (open drain)
    output reg       ack_valid_n              // 0->valid module is writing to bus
    output reg [1:0] winner_source_id         // source ID of the winner of the arbitration
);

always @(*) begin 
    //default values
    ack_ready_to_module = 4'b0;
    ack_valid_n = 1'b1;
    winner_source_id = 2'b11;   //CTRL has default ownship of the bus

    // step 1: check the ack_valid signal for all modules to see if they are asserting ack signal
    //         if not, we can skip them

    // step 2: choose the winner among all the modules who is asserting ack signal

    if (ack_valid_from_modules > 4'b0) begin
      // at least one module asserts its ack signal
    end
end

endmodule