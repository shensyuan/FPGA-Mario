module Collision (
    input [9:0] PLAYER_X,
    input [9:0] PLAYER_Y,
    input [14:0] MAP_DATA_0,
    input [14:0] MAP_DATA_1,
    input [14:0] MAP_DATA_2,
    input [14:0] MAP_DATA_3,
    output [9:0] LIMIT_U_POS,
    output [9:0] LIMIT_D_POS,
    output LIMIT_U,
    output LIMIT_D,
    output LIMIT_L,
    output LIMIT_R,
    output [4:0] PLAYER_BLOCK_X,
    output [4:0] PLAYER_BLOCK_Y,
    output PLAYER_X_INBLOCK,
    output PLAYER_Y_INBLOCK
);

    // wire x_inblock = (PLAYER_X & `BLOCK_MASK) == 0;
    wire [9:0] x_box_left = PLAYER_X + (2 << `BLOCK_SCALE);
    wire [9:0] x_box_right = PLAYER_X + `BLOCK_WIDTH - (2 << `BLOCK_SCALE);
    // wire [9:0] x_block_box_left = (PLAYER_X >> `TO_BLOCK_SHIFT) << `TO_BLOCK_SHIFT;
    wire [9:0] x_block_box_left = x_box_left - (x_box_left & `BLOCK_MASK);
    wire [9:0] x_block_box_right = ((x_box_left >> `TO_BLOCK_SHIFT) + 1) << `TO_BLOCK_SHIFT;
    
    wire [4:0] x_block = x_box_left >> `TO_BLOCK_SHIFT;
    wire x_inblock = (x_box_left >= x_block_box_left) && (x_box_right <= x_block_box_right);
    wire x_leftist = x_box_left == x_block_box_left;
    wire x_rightist = x_box_right == x_block_box_right;

    wire [4:0] y_block = PLAYER_Y >> `TO_BLOCK_SHIFT;
    wire y_inblock = (PLAYER_Y & `BLOCK_MASK) == 0;

    wire [14:0] c_blocks = x_inblock ? MAP_DATA_1 : (MAP_DATA_1 | MAP_DATA_2);
    wire [14:0] l_blocks = (x_block == 0 ? 15'd0 : MAP_DATA_0);
    wire [14:0] r_blocks = x_inblock ? (x_block == 19 ? 15'd0 : MAP_DATA_2) : (x_block >= 18 ? 8'hff : MAP_DATA_3);

    wire limit_u = (y_block == 0) | c_blocks[y_block-1];
    wire limit_d = (y_block == 14) | c_blocks[y_block+(y_inblock?1 : 2)];

    assign LIMIT_U_POS = limit_u ? PLAYER_Y - (PLAYER_Y & `BLOCK_MASK) : 10'd0;
    assign LIMIT_D_POS = (limit_d ? (y_inblock ? PLAYER_Y : ((PLAYER_Y >> `TO_BLOCK_SHIFT) + 1) << `TO_BLOCK_SHIFT) : 10'd1023);

    assign LIMIT_U = limit_u;
    assign LIMIT_D = limit_d;
    assign LIMIT_L = x_leftist & (l_blocks[y_block] | (!y_inblock & l_blocks[y_block+1]));
    assign LIMIT_R = x_rightist & (r_blocks[y_block] | (!y_inblock & r_blocks[y_block+1]));

    assign PLAYER_BLOCK_X = x_block;
    assign PLAYER_BLOCK_Y = y_block;
    assign PLAYER_X_INBLOCK = x_inblock;
    assign PLAYER_Y_INBLOCK = y_inblock;
endmodule
