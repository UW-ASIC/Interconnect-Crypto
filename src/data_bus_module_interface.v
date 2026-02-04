module data_bus_module_interface (
    // input from global arbiter
    input [3:0] rd_grant,   
    input [7:0] data_in,

    // output to the global arbiter
    output reg [7:0] data_out,
    output reg rdy_out,     // do we need rdy?
    output reg valid_out,

    // input from the module (e.g. from SHA, AES)
    input [7:0] data_from_module,
    input valid_from_module,

    // output to the module
    output reg [7:0] data_to_module,
    output reg valid_to_module
);

always @(*) begin
    // defaults
    valid_out = 1'b0;
    valid_to_module = 1'b0;

    data_to_module = data_in;

    // if the rd_grant signal to a module is valid, 
    // then the data send to the module is also valid
    if (rd_grant[0] == 1'b1) begin
        valid_to_module = 1'b1;
    end

    data_out = data_from_module;

    // if the data from module is valid, 
    // then the data_out to the global arbiter is also valid
    if (valid_from_module == 1'b1) begin
        valid_out = 1'b1;
    end
end



endmodule