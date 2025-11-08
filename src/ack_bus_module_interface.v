module ack_bus_module_interface (
    input  wire        ACK_READY,
    output wire        ACK_VALID,
    output wire [1:0]  MODULE_SOURCE_ID,
);



  always @(*) begin
    if (!rst_n) begin
      ack_reg <= 4'b0000;
    end else begin
      ack_reg <= req; // Simple acknowledgment logic: ack mirrors req
    end
  end

  assign ack = ack_reg;


endmodule
