`define H_START 10'd144
`define V_START 10'd35

module VGA_Output (
    input CLK,
    input [11:0] RGB_INPUT,
    output [9:0] RENDER_X,
    output [9:0] RENDER_Y,
    output reg [3:0] VGA_R,
    output reg [3:0] VGA_G,
    output reg [3:0] VGA_B,
    output reg VGA_HS,
    output reg VGA_VS
);
    reg counter = 0;
    reg [9:0] h_pos = 10'd0;
    reg [9:0] v_pos = 10'd0;

    assign RENDER_X = h_pos - `H_START;
    assign RENDER_Y = v_pos - `V_START;

    always @(posedge CLK) begin
        counter = ~counter;

        if (counter == 1'b0) begin
            h_pos <= h_pos + 10'd1;
            if (h_pos == 10'd799) begin
                h_pos <= 10'd0;
                v_pos <= v_pos == 10'd524 ? 0 : v_pos + 10'd1;
            end

            VGA_HS <= h_pos < 10'd96 ? 0 : 1;
            VGA_VS <= v_pos < 10'd2 ? 0 : 1;

            if (
                h_pos >= `H_START && h_pos < (`H_START + 10'd640) &&
                v_pos >= `V_START && v_pos < (`V_START + 10'd480)
            ) begin
                {VGA_R, VGA_G, VGA_B} <= RGB_INPUT;
            end else begin
                {VGA_R, VGA_G, VGA_B} <= 12'h0;
            end
        end
    end

endmodule
