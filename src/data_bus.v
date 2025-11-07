module data_bus(
    input reg clk, 
    input reg reset,
    input reg ready_in,
    input reg valid_in,
    input reg [1:0] source_id,
    output reg [1:0] destination_id,
    input reg [7:0] data_in, // input/received data from other components
    output reg ready, 
    output reg valid, 
    output reg [7:0] data_out, // what the module will send out to bus (to destination)  
    inout reg [7:0] bus_data // actual bus_line (assuming modules only use when have ACK)
)

// Give this file/module to the other teams to connect to (sending and receiving) 
// --> they can make their own instance and connect to it


// Receiving
always @(posedge clk) begin 
    if (reset) begin
        data_in <= 0;
    end else begin
        if(valid_in && ready_in) begin
            data_in <= bus_data; 
            //Do we need to reformat data_in when sending it out to data? (Endianness, Field width) Otherwise we'd need a formatter
                //Key question: Is the accpeting format of data for each component different?
            // grab data from bus and assign to data_in
            // Clarify what it'd do when both not high
        end else begin
            data_in <= 0;
        end
    end 
end

// Sending
always @(posedge clk) begin 
    if(reset) begin 
        data_out <= 0;
    end else begin
        if(ready && valid) begin 
            data_out <= bus_data; 

            // put data on the bus (serial communication??)
            // How are we checking if the reciever correctly receives it
            
        end else begin 
            data_out <= 0; // assuming that a module is onnly using bus when receiving ACK 
        end 
    end 
end 

endmodule

// How are we going to interact with ack bus?
// Do we need actual bus (tri-state driver)?
// How are other teams planning to interact with system
// How are we using source and destination? Where do they come from? How are they verified?

// Some skeleton for the actual bus
module actual_bus(
    input wire [7:0] data,
    input wire [7:0] drive_data,
    input wire dr_enable

)

wire [7:0] bus_line; // make the hardware for a 'bus'?
assign bus_line = dr_enable ? drive_data : 8'bz // If not enable then all zs?

endmodule