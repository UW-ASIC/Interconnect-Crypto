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
    
    // 1hot
    output reg [3:0] rd_grant,
    // encoded
    output reg [1:0] data_sel,
    output reg [1:0] rdy_sel
);
    //src/dest ids
    localparam [1:0] ctrl_id = 2'b11, mem_id = 2'b00, aes_id = 2'b10, sha_id = 2'b01;
    // module one hot encode
    localparam [3:0] ctrl_1hot = 4'b1000, aes_1hot = 4'b0100, sha_1hot = 4'b0010, mem_1hot = 4'b0001;
    // opcode type
    localparam [1:0] hash_op = 2'b11;
    // ? tbd
    // default control ? after opcode byte handshaked goes to tansmission, back when ack bus handshake
    localparam [1:0] idle = 2'd0, hash_op_wait_ready = 2'd1, addr = 2'd2, module_transmission = 2'd3;

    // mux sel
    reg [1:0] n_data_sel, n_rdy_sel;
    // rd grant
    reg [1:0] n_rd_grant;
    // state of the bus
    reg [1:0] state, n_state;

    // counter if mem include
    reg [1:0] counter, n_counter;
    
    // slice opcode
    wire [1:0] dest, src, opcode;
    // latch src and dest
    reg[1:0] dest_latch, src_latch, n_dest_latch, n_src_latch;

    assign dest = data_on_bus[5:4], src = data_on_bus[3:2], opcode = data_on_bus[1:0];

    // handshakes on data/ack bus
    wire data_bus_fire, ack_bus_fire;
    assign data_bus_fire = valid_on_bus && ready_on_bus;
    assign ack_bus_fire = valid_on_ack && ready_on_ack && (id_on_ack == src_latch);

    // sequential
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 0;
            counter <= 0;

            data_sel <= 0;
            rd_grant <= 0;

            dest_latch <= 0;
            src_latch <= 0;

        end else begin
            state <= n_state;
            counter <= n_counter;

            data_sel <= n_data_sel;
            rd_grant <= n_rd_grant;

            dest_latch <= n_dest_latch;
            src_latch <= n_src_latch;
        end
    end 
    
    // next state/sel computing
    always @(*) begin
        // comb default
        n_state = state;
        n_counter = counter;

        n_data_sel = data_sel;
        n_rd_grant = rd_grant;

        n_dest_latch = dest_latch;
        n_src_latch = src_latch;

        case (state)
            // when ctrl owns the bus by default
            idle: begin
                n_counter = 0;
                n_dest_latch = 0;
                n_src_latch = 0;
                // control owns the bus by default
                n_data_sel = ctrl_id;
                n_rd_grant = ctrl_1hot;

                if(valid_on_bus) begin
                    // keep same
                    if (opcode == hash_op) begin
                        n_rd_grant = (dest == aes_id) ? aes_1hot : (dest == sha_id) ? sha_1hot : 4'b0000;
                        n_rdy_sel = dest;//should never be 4'b0000 otherwise control is cooked
                        n_state = hash_op_wait_ready;
                    end else begin
                        // handshake
                        n_state = ready_on_bus ? addr : idle;
                        n_rdy_sel = dest;

                        n_rd_grant = (dest == aes_id) ? aes_1hot : (dest == sha_id) ? sha_1hot : (dest == mem_id) ? mem_1hot: ctrl_1hot; // dest decode
                        // let source module
                        if (!ready_on_bus) begin
                            case (src)
                                mem_id: n_rd_grant |= mem_1hot;
                                aes_id: n_rd_grant |= aes_1hot;
                                sha_id: n_rd_grant |= sha_1hot;
                                default:;
                            endcase
                        end

                        if (ready_on_bus) begin
                            case (src)
                                aes_id: n_rd_grant &= ~aes_1hot;
                                sha_id: n_rd_grant &= ~sha_1hot;
                                default:;
                            endcase
                        end

                        n_src_latch = ready_on_bus ? src : 0;
                        n_dest_latch = ready_on_bus ? dest : 0;
                    end
                end                
            end 
            // when the opcode is xx xx xx 11 hashing operation, wait for fire (ideally 1 cycle but could more than that if the sha/aes is not ready)
            hash_op_wait_ready: begin
                if (data_bus_fire) begin
                    n_state = idle;
                end
            end
            // when src/dest contains mem, count 3 handshake update ownership
            addr: begin
                // count the handshake
                n_counter = data_bus_fire ? counter + 1: counter;

                // when 2 beat handshaked and the third handshake 
                if (counter == 2 && data_bus_fire) begin
                    n_state = module_transmission;
                    n_data_sel = src_latch;
                    n_rdy_sel = dest_latch;
                    // reset~ counter
                    n_counter = 0;

                end
            end
            // src module now owns the bus and ownership will be return upon ack handshake on ack bus
            module_transmission: begin
                n_counter = 0;
                n_data_sel = src_latch;
                n_rdy_sel = dest_latch;

                if (ack_bus_fire) begin
                    n_data_sel = ctrl_id;
                    n_rdy_sel = ctrl_id;
                    n_state = idle;
                    n_src_latch = 0;
                    n_dest_latch = 0;
                end
            end

            default:; 
        endcase

    end
endmodule