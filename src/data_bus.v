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

    // Arbitration 
    input  wire        bus_grant,  // bus grant from arbiter

    // Shared bus
    inout  wire [7:0]  bus_data,        
    inout  wire        bus_valid,
    output reg         bus_ready
);

    // --- Internal state ---
    reg driving;
    reg transaction_active;

    // Separate flags for send/receive
    reg first_pkt_received;

    // Grab and store source/destination from first packet
    reg [1:0] allowed_source; 
    reg [1:0] allowed_dest;   

    // --- Tri-state bus drivers ---
    assign bus_data  = (driving && transaction_active) ? send_data : 8'bz;
    assign bus_valid = (driving && transaction_active) ? 1'b1 : 1'bz;

    // --- Sending logic ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            driving             <= 0;
            transaction_active  <= 0;
            send_ready          <= 0;

        end else begin
            // Reset transaction if bus grant lost
            if (!bus_grant) begin
                driving            <= 0;
                transaction_active <= 0;
                send_ready         <= 0;

            end else begin
                // Start a new transaction
                if (!transaction_active && send_valid) begin
                    driving            <= 1;
                    transaction_active <= 1;
                    send_ready         <= 1;
                end

                // Keep send_ready high during transaction
                if (transaction_active)
                    send_ready <= 1;

                // End transaction on last packet
                if (driving && ack) begin
                    driving            <= 0;
                    transaction_active <= 0;
                end
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
                if (!first_pkt_received) begin
                    allowed_source      <= bus_data[5:4];
                    allowed_dest        <= bus_data[3:2];
                    first_pkt_received  <= 1;
                end

                // Only allow reading if this module is source or destination
                if (source_id == allowed_source || source_id == allowed_dest) begin
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
                bus_ready  <= 0;
                first_pkt_received <= 0; // ready for next transaction
            end
        end
    end

endmodule
