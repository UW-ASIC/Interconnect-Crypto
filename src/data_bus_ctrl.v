`default_nettype none
`timescale 1ns/1ps

module data_bus_ctrl (
    input wire clk,
    input wire rst_n,
    // data bus handshake
    input wire [7:0] data_on_bus,
    input wire valid_on_bus,
    input wire ready_on_bus,

    // ack bus handshake
    input wire[1:0] id_on_ack,
    input wire ready_on_ack,
    input wire valid_on_ack,
    
    // one hot？ could be encoded? no it will be encoded yes 0b11 means nobody read
    output reg [1:0] rd_grant,
    // encoded
    output reg [1:0] owner
);
    //src/dest ids
    localparam [1:0] ctrl_id = 2'b11, mem_id = 2'b00, aes_id = 2'b10, sha_id = 2'b01;

    // opcode type
    localparam [1:0] hash_op = 2'b11;
    // ? tbd
    // default control ? after opcode byte handshaked goes to tansmission, back when ack bus handshake
    localparam [3:0] idle = 4'b0, addr = 4'b1, module_transmission = 4'b2;

    // owner of the bus
    // reg [1:0] owner, n_owner;
    reg [1:0] n_owner;
    // state of the bus
    reg [1:0] state, n_state;

    // counter if mem include
    reg [1:0] coutner, n_counter;
    
    // slice opcode
    wire [1:0] dest, src, opcode;
    // latch src and dest
    reg[1:0] dest_latch, src_latch, n_dest_latch, n_src_latch;
    // latch opcode ? maybe?
    // reg[1:0] opcode_latch, n_opcode_latch;
    assign dest = data_on_bus[5:4], src = data_on_bus[3:2], opcode = data_on_bus[1:0];

    // handshakes on data/ack bus
    wire data_bus_fire, ack_bus_fire;
    assign data_bus_fire = valid_on_bus && ready_on_bus;
    assign ack_bus_fire = valid_on_ack && ready_on_ack && (id_on_ack == src_latch);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            owner <= 0;
            state <= 0;
            coutner <= 0;

            // opcode_latch <= 0;
            dest_latch <= 0;
            src_latch <= 0;

        end else begin
            owner <= n_owner;
            state <= n_state;
            coutner <= n_counter;

            // opcode_latch <= n_opcode_latch;
            dest_latch <= n_dest_latch;
            src_latch <= n_src_latch;

        end
    end 
    
    // next state/owner computing
    always @(*) begin
        // comb default
        n_owner = owner;
        n_state = state;

        n_counter = counter;

        // n_opcode_latch = opcode_latch;
        n_dest_latch = dest_latch;
        n_src_latch = src_latch;

        case (state)
            // when ctrl owns the bus by default
            idle: begin
                n_counter = 0;
                n_opcode_latch = 0;
                n_dest_latch = 0;
                n_src_latch = 0;
                n_owner = ctrl_id
                if(valid_on_bus) begin
                    // keep same
                    if (opcode == hash_op) begin
                        n_state = idle; //????????
                    end else begin
                        // handshake
                        n_state = ready_on_bus ? addr : idle;
                        n_owner = ready_on_bus ? ctrl_id : owner;

                        // n_opcode_latch = ready_on_bus ? opcode : 0;
                        n_src_latch = ready_on_bus ? src : 0;
                        n_dest_latch = ready_on_bus ? dest : 0;
                    end

                end
                
                
            end 
            // when src/dest contains mem, count 3 handshake update ownership
            addr: begin
                // count the handshake
                n_counter = data_bus_fire ? counter + 1: counter;

                // when 2 beat handshaked and the third handshake 
                if (counter == 2 && data_bus_fire) begin
                    n_state = module_transmission;
                    n_owner = src_latch;
                    // reset~ counter
                    n_counter = 0;

                end
            end
            // src module now owns the bus and ownership will be return upon ack handshake on ack bus
            module_transmission: begin
                n_counter = 0;
                n_owner = src_latch;

                if (ack_bus_fire) begin
                    n_owner = ctrl_id;
                    n_state = idle;
                    n_src_latch = 0;
                    n_dest_latch = 0;
                    // n_opcode_latch = 0;
                end

            end


            default:; 
        endcase

    end

    // comb rd grant
    always @(*) begin
        case (state)
        // idle
            idle: begin
                rd_grant = ctrl_id;
                if (valid_on_bus) begin
                    rd_grant = dest;
                end
            end 
        // addr
            addr: begin
                rd_grant = dest_latch;              
            end
        // module_transmission
            module_transmission: begin
                rd_grant = dest_latch;
                if (ack_bus_fire) begin
                    rd_grant = ctrl_id;
                end
            end
            default: 
        endcase
    end

endmodule        