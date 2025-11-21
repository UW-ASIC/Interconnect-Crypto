module data_bus(
    input  wire        clk,
    input  wire        rst_n,      // active low

    // Sending
    input  wire        send_valid,  // data (to send) is valid 
    input  wire [7:0]  send_data,   // data (to send)
    output reg         send_ready,  // sender can send
    input  wire        ack,         // marks last packet to send
    // Receiving
    input  wire [1:0]  source_id,  // this module's ID
    output reg         recv_valid, // valid data for this module
    output reg [7:0]   recv_data,  // data being received

    // Shared bus
    inout  wire [7:0]  bus_data,        
    inout  wire        bus_valid,
);


    // --- Internal state ---
    reg driving;
    reg ownership;

    // Separate flags for send/receive
    reg first_pkt_received;
    reg read_address;
    reg bus_ready;

    // Grab and store source/destination from first packet
    reg [2:0] allowed_source; 
    reg [2:0] allowed_dest;   

    integer i = 0;

    // --- Tri-state bus drivers ---
    assign bus_data  = (driving && ownership) ? send_data : 8'bz;
    assign bus_valid = (driving && ownership) ? 1'b1 : 1'bz;

    // --- Sending logic ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            driving             <= 0;
            ownership           <= 0;
            send_ready          <= 0;
            first_pkt_received  <= 0;

        end else begin

            if(ack) begin  // reset all internal signals
                driving <= 0;
                allowed_source <= 4;
                allowed_dest <= 4;
                send_ready <= 0;
                first_pkt_received <= 0;
                ownership <= 0;    
                read_address <= 0;
            end 

            if(source_id == 11 && send_valid) begin  // if control, just let them send whatever they feel like (if they assert send_valid)
                bus_data <= send_data;
                bus_valid <= send_valid;
                driving <= 1;
                first_pkt_received <= 1;
                read_address <= 1; // modules should read the first packet

            end else if (source_id == 11 && send_valid && first_pkt_received) begin 
                bus_data <= send_data;
                bus_valid <= send_valid;
                driving <= 1;
                read_address <= 0; // modules should read the first packet
                i = i + 1;
            
            end else if(i == 3 && source_id == allowed_source[1:0]) begin // now src has bus ownership
                ownership <= 1;
            end 
            
            if(ownership) begin  // you are the owner
                if(send_valid && bus_ready) begin // you have valid data + bus is ready --> send it over captain!
                    bus_data <= send_data;
                    bus_valid <= send_valid;
                    driving <= 1;
                    send_ready <= bus_ready;
                end 

            end else begin // you are not the owner --> don't touch!
                driving <= 0;
                send_ready <= 0;
            end
        end
    end



    // --- Receiving logic ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            recv_valid           <= 0;
            recv_data            <= 0;
            first_pkt_received   <= 0;
            allowed_source       <= 0;
            allowed_dest         <= 0;
            bus_ready            <= 0;

        end else begin
            if (bus_valid === 1'b1) begin

                // Grab src and dest from first packet
                if (read_address) begin
                    allowed_source      <= {1'b0, bus_data[5:4]};
                    allowed_dest        <= {1'b0, bus_data[3:2]};
                end

                // Only allow reading if this module is source or destination
                if (source_id == allowed_source[1:0] || source_id == allowed_dest[1:0]) begin
                    recv_valid <= 1;
                    recv_data  <= bus_data;
                    bus_ready  <= 1;

                end else begin
                    recv_valid <= 0;
                    recv_data  <= 0;
                    bus_ready  <= 0;
                end

            end else begin
                recv_valid <= 0;
                recv_data  <= 0;
            end
        end
    end

endmodule
