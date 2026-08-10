`timescale 1ns/1ps

module i2c_master (
    input  wire       clk,
    input  wire       reset,
    input  wire       start,
    input  wire [6:0] slave_addr,
    input  wire       rw,          // 0 = Write, 1 = Read
    input  wire [7:0] tx_data,

    output reg  [7:0] rx_data,
    output reg        busy,
    output reg        done,

    inout  wire       sda,
    output reg        scl
);

    reg sda_out;
    reg sda_oe;

    assign sda = sda_oe ? sda_out : 1'bz;

    reg [3:0] state;
    reg [3:0] bit_count;

    reg [7:0] shift_reg;

    localparam IDLE      = 4'd0;
    localparam START     = 4'd1;
    localparam ADDR      = 4'd2;
    localparam ADDR_ACK  = 4'd3;
    localparam WRITE     = 4'd4;
    localparam WRITE_ACK = 4'd5;
    localparam READ      = 4'd6;
    localparam READ_ACK  = 4'd7;
    localparam STOP      = 4'd8;
    localparam FINISH    = 4'd9;

    always @(posedge clk or posedge reset) begin

        if (reset) begin

            state     <= IDLE;
            bit_count <= 0;
            shift_reg <= 0;

            rx_data   <= 0;
            busy      <= 0;
            done      <= 0;

            scl       <= 1'b1;

            sda_out   <= 1'b1;
            sda_oe    <= 1'b1;

        end

        else begin

            done <= 1'b0;

            case (state)

                IDLE: begin

                    busy <= 1'b0;
                    scl  <= 1'b1;

                    sda_out <= 1'b1;
                    sda_oe  <= 1'b1;

                    if (start) begin

                        busy <= 1'b1;

                        shift_reg <= {slave_addr, rw};

                        bit_count <= 7;

                        state <= START;

                    end

                end

                // START condition
                START: begin

                    sda_out <= 1'b0;
                    sda_oe  <= 1'b1;

                    scl <= 1'b1;

                    state <= ADDR;

                end

                // Send address + R/W bit
                ADDR: begin

                    scl <= 1'b0;

                    sda_out <= shift_reg[bit_count];

                    scl <= 1'b1;

                    if (bit_count == 0) begin

                        state <= ADDR_ACK;

                    end

                    else begin

                        bit_count <= bit_count - 1'b1;

                    end

                end

                // Address ACK
                ADDR_ACK: begin

                    scl <= 1'b0;

                    sda_oe <= 1'b0;

                    scl <= 1'b1;

                    sda_oe <= 1'b1;

                    if (rw == 1'b0) begin

                        shift_reg <= tx_data;
                        bit_count <= 7;

                        state <= WRITE;

                    end

                    else begin

                        shift_reg <= 0;
                        bit_count <= 7;

                        state <= READ;

                    end

                end

                // Write data
                WRITE: begin

                    scl <= 1'b0;

                    sda_out <= shift_reg[bit_count];

                    scl <= 1'b1;

                    if (bit_count == 0) begin

                        state <= WRITE_ACK;

                    end

                    else begin

                        bit_count <= bit_count - 1'b1;

                    end

                end

                // Data ACK
                WRITE_ACK: begin

                    scl <= 1'b0;

                    sda_oe <= 1'b0;

                    scl <= 1'b1;

                    sda_oe <= 1'b1;

                    state <= STOP;

                end

                // Read data
                READ: begin

                    scl <= 1'b0;

                    sda_oe <= 1'b0;

                    scl <= 1'b1;

                    shift_reg[bit_count] <= sda;

                    if (bit_count == 0) begin

                        state <= READ_ACK;

                    end

                    else begin

                        bit_count <= bit_count - 1'b1;

                    end

                end

                // Master ACK after read
                READ_ACK: begin

                    scl <= 1'b0;

                    sda_oe  <= 1'b1;
                    sda_out <= 1'b0;

                    scl <= 1'b1;

                    rx_data <= shift_reg;

                    state <= STOP;

                end

                // STOP condition
                STOP: begin

                    scl <= 1'b1;

                    sda_out <= 1'b0;

                    sda_oe <= 1'b1;

                    sda_out <= 1'b1;

                    state <= FINISH;

                end

                FINISH: begin

                    busy <= 1'b0;
                    done <= 1'b1;

                    scl <= 1'b1;
                    sda_out <= 1'b1;

                    state <= IDLE;

                end

                default: begin
                    state <= IDLE;
                end

            endcase

        end

    end

endmodule