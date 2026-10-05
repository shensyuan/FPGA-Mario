module FinalProject (
    //////////// CLOCK //////////
    input ADC_CLK_10,
    input MAX10_CLK1_50,
    input MAX10_CLK2_50,

    //////////// SEG7 //////////
    output [7:0] HEX0,
    output [7:0] HEX1,
    output [7:0] HEX2,
    output [7:0] HEX3,
    output [7:0] HEX4,
    output [7:0] HEX5,

    //////////// KEY //////////
    input [1:0] KEY,

    //////////// LED //////////
    output [9:0] LEDR,

    //////////// SW //////////
    input [9:0] SW,

    //////////// VGA //////////
    output [3:0] VGA_B,
    output [3:0] VGA_G,
    output [3:0] VGA_R,
    output       VGA_HS,
    output       VGA_VS,

    //////////// Dot Matrix //////////
    output [7:0] ROW,
    output [7:0] COL_0,
    output [7:0] COL_1,

    //////////// Key Pad //////////
    input  [3:0] K_COL,
    output [3:0] K_ROW,

    //////////// Arduino //////////
    inout [15:0] ARDUINO_IO,
    inout        ARDUINO_RESET_N
);
    assign HEX0[7] = 1;
    assign HEX1[7] = 1;
    assign HEX2[7] = 1;
    assign HEX3[7] = 1;
    assign HEX4[7] = 1;
    assign HEX5[7] = 1;

    wire [ 9:0] render_x;
    wire [ 9:0] render_y;
    wire [11:0] rgb_output;
    wire [ 3:0] k_keyboard;
    wire [ 3:0] keyboard = SW[0] ? k_keyboard : ARDUINO_IO[3:0];

    wire [ 1:0] count_state;
    wire [23:0] counter;

    wire is_jump;

    Game game (
        .CLK(MAX10_CLK1_50),
        .RST_N(KEY[0]),
        .KEYBOARD(keyboard),
        .RENDER_X(render_x),
        .RENDER_Y(render_y),
        .RGB_OUTPUT(rgb_output),
        .COUNT_STATE(count_state),
        .COUNTER(counter),
        .IS_JUMP(is_jump)
    );

    VGA_Output vga_out (
        .CLK(MAX10_CLK1_50),
        .RGB_INPUT(rgb_output),
        .RENDER_X(render_x),
        .RENDER_Y(render_y),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_VS(VGA_VS),
        .VGA_HS(VGA_HS)
    );
    assign LEDR[3:0] = keyboard;

    KeyPadController k_controller (
        .CLK(MAX10_CLK2_50),
        .K_COL(K_COL),
        .K_ROW(K_ROW),
        .KEYBOARD(k_keyboard),
        .COUNT_STATE(count_state),
    );

    DotMatrix_Output dotmatrix_test (
        .CLK(MAX10_CLK2_50),
        .ROW(ROW),
        .COL({COL_1, COL_0}),
        .IS_WALK(keyboard[2] | keyboard[3]),
        .REVERSE(keyboard[2])
    );

    SegDecoder seg0 (
        .CLK(MAX10_CLK2_50),
        .VAL(counter[3:0]),
        .ANI(counter == 24'hffffff),
        .OUT(HEX0[6:0])
    );
    SegDecoder seg1 (
        .CLK(MAX10_CLK2_50),
        .VAL(counter[7:4]),
        .ANI(counter == 24'hffffff),
        .OUT(HEX1[6:0])
    );
    SegDecoder seg2 (
        .CLK(MAX10_CLK2_50),
        .VAL(counter[11:8]),
        .ANI(counter == 24'hffffff),
        .OUT(HEX2[6:0])
    );
    SegDecoder seg3 (
        .CLK(MAX10_CLK2_50),
        .VAL(counter[15:12]),
        .ANI(counter == 24'hffffff),
        .OUT(HEX3[6:0])
    );
    SegDecoder seg4 (
        .CLK(MAX10_CLK2_50),
        .VAL(counter[19:16]),
        .ANI(counter == 24'hffffff),
        .OUT(HEX4[6:0])
    );
    SegDecoder seg5 (
        .CLK(MAX10_CLK2_50),
        .VAL(counter[23:20]),
        .ANI(counter == 24'hffffff),
        .OUT(HEX5[6:0])
    );
endmodule
