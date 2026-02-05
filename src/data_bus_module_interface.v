module data_bus_module_interface (
    // input from global arbiter
    input rd_grant,   
    input [9:0] data_in, // [9]:ready, [8]:valid, [7:0]:data

    // output to the global arbiter
    output reg [9:0] data_out,

    // input from the module (e.g. from SHA, AES)
    input [9:0] data_from_module,

    // output to the module
    output reg [9:0] data_to_module,
);

always @(*) begin

    // if rd_grant is high, pass the data_in to the module
    if (rd_grant) data_to_module = data_in;
    // if rd_grant is low, manually change the valid bit of the data to 0
    else data_to_module = {data_in[9], 1'b0, data_in[7:0]};

    data_out = data_from_module;
end



endmodule