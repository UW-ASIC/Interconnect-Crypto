// Actual file
/* What this module does:
    - Other modules will make their own instance of this module for sending and receiving data
    - inputs: used for sending data
    - outputs: used for receiving data  
*/


module data_bus_device(
    input  wire        clk,
    input  wire        rst_n,

    // Sending
    input  wire        send_valid, 
    input  wire [7:0]  send_data,
    output reg         send_ready,

    // Receiving
    output reg         recv_valid,
    output reg  [7:0]  recv_data,

    // Arbitration control
    input  wire        bus_grant, // given by arbiter (good to check)

    // Shared bus
    inout  wire [7:0]  bus_data,
    inout  wire        bus_valid
);

    reg driving;

    // Tri-state driver
    assign bus_data  = (driving && bus_grant) ? send_data : 8'bz;
    assign bus_valid = (driving && bus_grant) ? 1'b1      : 1'bz;

    // Driving logic
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            driving   <= 0; 
            send_ready <= 0;
        end else if(bus_grant && send_valid) begin
            driving   <= 1;
            send_ready <= 1;
        end else begin
            driving   <= 0;
            send_ready <= 0;
        end
    end

    // Receive logic
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            recv_valid <= 0;
            recv_data  <= 0;
        end else if(!bus_grant && bus_valid === 1'b1) begin
            recv_valid <= 1;
            recv_data  <= bus_data;
        end else begin
            recv_valid <= 0;
        end
    end

endmodule

//wait i bl

// // (This is just me ironing out my thoughts lol)
// module data_bus(
//     input wire clk, 
//     input wire rst_n,

//     // ports (for sending to bus)
//     input wire valid, // data to send is valid
//     input wire [7:0] data, // data to send
//     output wire ready, // we sent it... 

//     input wire [1:0] source_id;

//     // outputs (for receiving from bus)
//     input wire ready_in, // module is ready to receive inputs
//     output wire valid_in, // we are receiving valid data
//     output wire [7:0] data_in, // the data

//     // actual bus
//     inout wire [7:0] bus_line, // actual bus_line (assuming modules only use when have ACK)
//     inout wire bus_ready,
//     inout wire bus_valid, // data is valid
// );

// // Internal states:
// reg [7:0] packet = 0;
// reg [7:0] received_data = 0;
// reg is_target = 0;

// // Receiving from bus
// always @(posedge clk) begin 
//     if (rst_n! || !ready_in) begin
//         data <= 0;
//         valid_in <= 0;
//         received_data <= 0;

//     end else begin
//         // if bus data is valid and ready to receive:
//         if(ready_in && bus_valid) begin 
//             packet <= bus_line; // get the first packet from shared bus            
            
//             // Check if you (the module connected to the instance) are the target/destination
//             if(packet[5:4] == source_id || is_target) begin 
//                 received_data <= bus_line;
//                 valid_in <= 1;
//                 is_target <= 1;
//                 assign bus_ready <= 1; // we got the data, gimme next packet

//             end else begin 
//                 valid_in <= 0;
//                 received_data <= 0;
//                 is_target <= 0
//             end 

//         // Not ready to receive
//         end else if(bus_data && is_target) begin
//             is_target <= 1;
//             assign bus_ready <= 0;

//         // You are not the destination...
//         end else begin 
//             valid_in <= 0;
//             received_data <= 0;
//             is_target <= 0;
//         end 
//     end 
// end

// // Sending --> assuming only the correct module is sending to bus (i.e. arbiter takes care of it)
// always @(posedge clk) begin 
//     if(!rst_n) begin 
//         ready <= 0
//     end else begin
//         // if data is valid and other module is ready, send it...
//         if(valid && bus_ready) begin
//             assign bus_valid <= 1;
//             assign bus_line <= data;
//             ready <= 1; // we sent it
//         end else begin
//             ready <= 0; // module has to stall
//         end
//     end 
// end 

// assign data_in = received_data;

// endmodule
