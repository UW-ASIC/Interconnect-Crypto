module data_bus(
    input  wire        clk,
    input  wire        rst_n,      // active low

    // Sending
    input  wire        send_valid,  // data (to send) is valid 
    input  wire [7:0]  send_data,   // data (to send)
    output reg         send_ready,  // sender can send
    input  wire        ack,         // marks last packet to send

    // Receiving
    input  wire [1:0]  source_id,   // this module's ID
    output reg         recv_valid,  // valid data for this module
    output reg  [7:0]  recv_data,   // data being received

    // Shared bus
    inout  wire [7:0]  bus_data,        
    inout  wire        bus_valid
);

    // --- Internal state ---
    reg ownership;

    // Separate flags for send/receive
    reg first_pkt_received;
    reg read_address;
    reg bus_ready = 1;

    // Grab and store source/destination from first packet
    reg [2:0] allowed_source = 7; 
    reg [2:0] allowed_dest = 7;   

    reg [2:0] i = 0; // wait 3 cycles for control

    // wires
    wire is_control = (source_id == 2'b11 && send_valid);
    wire is_bus_owner = (i == 3 && {1'b0, source_id} == allowed_source);

    // --- Tri-state bus drivers ---
    assign bus_data  = (ownership && (is_control || is_bus_owner) && send_valid) ? send_data : 8'bz;
    assign bus_valid = (ownership && (is_control || is_bus_owner) && send_valid) ? 1'b1 : 1'bz;
// 
// --- Sending logic ---
    always @(*) begin

        ownership          = ownership;      // or 0 if you want default low
        send_ready         = 0;
        first_pkt_received  = first_pkt_received; // or 0
        read_address       = 0;
        
        if (!rst_n) begin
            ownership           = 0;
            send_ready          = 1; // Default High on Reset
            first_pkt_received  = 0;
            read_address        = 0;

        end else begin
            if(ack) begin 
                first_pkt_received  = 0;
                send_ready          = 1;
                ownership           = 0;    
                read_address        = 0;

            end else begin
                // ==========================================================
                // PART 1: UPDATE INTERNAL FLAGS (Run this independently)
                // ==========================================================
                if(bus_valid && !first_pkt_received) begin 
                    first_pkt_received  = 1;
                    read_address        = 1; 
                end else if (bus_valid && first_pkt_received) begin
                    read_address        = 0;
                end 

                // ==========================================================
                // PART 2: HANDLE OWNERSHIP & READY (Run this independently)
                // ==========================================================
                if(source_id == 2'b11 && send_valid) begin
                    ownership = 1;
                    send_ready = 1; // MUST be 1 immediately
                end


                // PRIORITY 1: Existing Ownership
                if(ownership) begin 
                    if(send_valid && bus_ready) begin
                        send_ready = 1; 
                    end else begin
                        send_ready = bus_ready; 
                    end
                end 
                
                // PRIORITY 3: Normal Modules (Must wait for first packet flag)
                else if (({1'b0, source_id} == allowed_source) && bus_valid && first_pkt_received) begin
                    if (i < 3) begin
                        send_ready = 0; 
                    end else begin
                        ownership = 1;
                        send_ready = 1;
                    end
                end 
            end
        end
    end

    // --- Receiving logic ---
    always @(*) begin
        recv_valid     = 0;
        recv_data      = 0;
        bus_ready      = 1;
        allowed_source = allowed_source;  // preserve (but prolly bad practice)
        allowed_dest   = allowed_dest;    // preserve
            
        if (!rst_n) begin
            recv_valid           = 0;
            recv_data            = 0;
            allowed_source       = 0;
            allowed_dest         = 0;
            bus_ready            = 1;

        end else begin

            if (ack) begin 
                allowed_source = 7;
                allowed_dest = 7;
            end 

            if (bus_valid == 1'b1) begin

                // Grab src and dest from first packet
                if (read_address && !ack) begin
                    allowed_source      = {1'b0, bus_data[3:2]};
                    allowed_dest        = {1'b0, bus_data[5:4]};
                end

                // Only allow reading if this module is source or destination
                if ({1'b0, source_id} == allowed_source || source_id == 2'b11 || {1'b0, source_id} == allowed_dest) begin
                    recv_valid = 1;
                    recv_data  = bus_data;
                    bus_ready  = 1;


                end else begin
                    recv_valid = 0;
                    recv_data  = 0;
                    bus_ready  = 0;
                end

            end else begin
                recv_valid = 0;
                recv_data  = 0;
            end
        end
    end



// wait 3 cycles

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        i <= 0;
    end else if (ack) begin
        i <= 0;
    end else if ({1'b0, source_id} == allowed_source && bus_valid && first_pkt_received) begin
        if (i < 3)
            i <= i + 1;
    end else if (ownership) begin
        // once owner is confirmed, freeze or reset
        i <= 0;
    end
end


endmodule