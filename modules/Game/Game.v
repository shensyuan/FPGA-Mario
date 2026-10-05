module Game (
    input CLK,
    input RST_N,
    input [3:0] KEYBOARD,
    input [9:0] RENDER_X,
    input [9:0] RENDER_Y,
    output [11:0] RGB_OUTPUT,
    input [1:0] COUNT_STATE,
    output [23:0] COUNTER,
    output IS_JUMP
);
    wire [9:0] player_x;
    wire [9:0] player_y;
    wire direction;
    wire walking;
    wire walking_animation;

    wire [7:0] map_index;
    wire [7:0] render_block_type;

    wire [9:0] limit_u;
    wire [9:0] limit_d;
    wire limit_l;
    wire limit_r;

    wire [23:0] death_count;
    wire [23:0] coin_count;
    assign COUNTER = COUNT_STATE == 2'b0 ? death_count : (COUNT_STATE == 2'b1 ? coin_count : 24'hffffff);

    assign IS_JUMP = player_y < limit_d;

    Render render (
        .CLK(CLK),
        .RENDER_X(RENDER_X),
        .RENDER_Y(RENDER_Y),
        .PLAYER_X(player_x),
        .PLAYER_Y(player_y),
        .ON_GROUND(limit_d),
        .DIRECTION(direction),
        .WALKING(walking),
        .WALKING_ANIMATION(walking_animation),
        .BLOCK_TYPE(render_block_type),
        .RGB_OUTPUT(RGB_OUTPUT)
    );

    MapParser parser (
        .CLK(CLK),
        .RST_N(RST_N),
        .MAP_INDEX(map_index),
        .RENDER_X(RENDER_X),
        .RENDER_Y(RENDER_Y),
        .PLAYER_X(player_x),
        .PLAYER_Y(player_y),
        .BLOCK_TYPE(render_block_type),
        .LIMIT_U_POS(limit_u),
        .LIMIT_D_POS(limit_d),
        .LIMIT_L(limit_l),
        .LIMIT_R(limit_r),
        .COIN_COUNT(coin_count)
    );

    PlayerController controller (
        .CLK(CLK),
        .RST_N(RST_N),
        .KEYBOARD(KEYBOARD),
        .LIMIT_U_POS(limit_u),
        .LIMIT_D_POS(limit_d),
        .LIMIT_L(limit_l),
        .LIMIT_R(limit_r),
        .PLAYER_X(player_x),
        .PLAYER_Y(player_y),
        .DIRECTION(direction),
        .WALKING(walking),
        .WALKING_ANIMATION(walking_animation),
        .MAP_INDEX(map_index),
        .DEATH_COUNT(death_count)
    );
endmodule
