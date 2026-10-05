`define S0 7'b1000000
`define S1 7'b1111001
`define S2 7'b0100100
`define S3 7'b0110000
`define S4 7'b0011001
`define S5 7'b0010010
`define S6 7'b0000010
`define S7 7'b1111000
`define S8 7'b0000000
`define S9 7'b0010000
`define SA 7'b0001000
`define SB 7'b0000011
`define SC 7'b1000110
`define SD 7'b0100001
`define SE 7'b0000110
`define SF 7'b0001110
`define SN 7'b1111111

module SegDecoder (
    input CLK,
    input ANI,
    input [3:0] VAL,
    output reg [6:0] OUT
);
    reg [5:0] ani_state = 6'b011111;
    reg [21:0] counter = 0;

    always @(posedge CLK) begin
        counter <= counter + 1;
        if (ANI) begin
            OUT = {1'b1, ani_state};
            if (counter == 0) begin
                ani_state = (~ani_state) >> 1;
                if (ani_state == 0) begin
                    ani_state = 6'b100000;
                end
                ani_state = ~ani_state;
            end
        end else begin
            case (VAL)
                4'h0:    OUT = `S0;
                4'h1:    OUT = `S1;
                4'h2:    OUT = `S2;
                4'h3:    OUT = `S3;
                4'h4:    OUT = `S4;
                4'h5:    OUT = `S5;
                4'h6:    OUT = `S6;
                4'h7:    OUT = `S7;
                4'h8:    OUT = `S8;
                4'h9:    OUT = `S9;
                4'ha:    OUT = `SA;
                4'hb:    OUT = `SB;
                4'hc:    OUT = `SC;
                4'hd:    OUT = `SD;
                4'he:    OUT = `SE;
                4'hf:    OUT = `SF;
                default: OUT = `SN;
            endcase
        end
    end

endmodule
