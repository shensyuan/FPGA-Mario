module Render (
    input CLK,
    input [9:0] RENDER_X,
    input [9:0] RENDER_Y,
    input [9:0] PLAYER_X,
    input [9:0] PLAYER_Y,
    input [9:0] ON_GROUND,
    input DIRECTION,
    input WALKING,
    input WALKING_ANIMATION,
    input [7:0] BLOCK_TYPE,
    output [11:0] RGB_OUTPUT
);
    reg [11:0] MARIO[`BLOCK_UNIT_SIZE];
    reg [11:0] MARIO_JUMP[`BLOCK_UNIT_SIZE];
    reg [11:0] MARIO_WALK_1[`BLOCK_UNIT_SIZE];
    reg [11:0] MARIO_WALK_2[`BLOCK_UNIT_SIZE];

    reg [11:0] GROUND[`BLOCK_UNIT_SIZE];
    reg [11:0] BLOCK[`BLOCK_UNIT_SIZE];
    reg [11:0] GOLD[`BLOCK_UNIT_SIZE];
    reg [11:0] GOLD_EMPTY[`BLOCK_UNIT_SIZE];
    reg [11:0] BRICK[`BLOCK_UNIT_SIZE];

    reg [11:0] rgb;
    reg [11:0] rgb_temp;
    reg draw;

    wire [9:0] unit_x_pos;
    wire [9:0] unit_y_pos;
    wire [9:0] unit_block_x_pos;
    wire [9:0] unit_block_y_pos;
    wire [31:0] flatten_pos;
    wire [31:0] flatten_block_pos;

    assign RGB_OUTPUT = rgb;

    assign unit_x_pos = (RENDER_X - PLAYER_X) >> `BLOCK_SCALE;
    assign unit_y_pos = (RENDER_Y - PLAYER_Y) >> `BLOCK_SCALE;

    assign unit_block_x_pos = (RENDER_X & `BLOCK_MASK) >> `BLOCK_SCALE;
    assign unit_block_y_pos = (RENDER_Y & `BLOCK_MASK) >> `BLOCK_SCALE;

    assign flatten_pos = unit_y_pos * `BLOCK_UNIT_WIDTH + (DIRECTION ? unit_x_pos : (`BLOCK_UNIT_WIDTH - unit_x_pos - 1));
    assign flatten_block_pos = unit_block_y_pos * `BLOCK_UNIT_WIDTH + unit_block_x_pos;

    initial begin
        $readmemh("data/Mario.hex", MARIO);
        $readmemh("data/Mario_Jump.hex", MARIO_JUMP);
        $readmemh("data/Mario_Walk1.hex", MARIO_WALK_1);
        $readmemh("data/Mario_Walk2.hex", MARIO_WALK_2);

        $readmemh("data/Ground.hex", GROUND);
        $readmemh("data/Block.hex", BLOCK);
        $readmemh("data/Gold.hex", GOLD);
        $readmemh("data/Gold_Empty.hex", GOLD_EMPTY);
        $readmemh("data/Brick.hex", BRICK);
    end

    always @(posedge CLK) begin
        draw = 0;

        if (RENDER_X >= PLAYER_X &&
            RENDER_X < PLAYER_X +`BLOCK_WIDTH &&
            RENDER_Y >= PLAYER_Y &&
            RENDER_Y < PLAYER_Y +
            `BLOCK_HEIGHT
            ) begin

            if (PLAYER_Y < ON_GROUND) rgb_temp = MARIO_JUMP[flatten_pos];
            else if (WALKING) begin
                if (WALKING_ANIMATION) rgb_temp = MARIO_WALK_1[flatten_pos];
                else rgb_temp = MARIO_WALK_2[flatten_pos];
            end else rgb_temp = MARIO[flatten_pos];

            if (rgb_temp != 0) begin
                rgb = rgb_temp;
                draw = 1;
            end
        end

        if (!draw) rgb = `BG_COLOR;

        case (BLOCK_TYPE)
            0: rgb = rgb;
            1: rgb = GROUND[flatten_block_pos];
            2: rgb = BLOCK[flatten_block_pos];
            3: rgb = GOLD[flatten_block_pos];
            4: rgb = GOLD_EMPTY[flatten_block_pos];
            5: rgb = BRICK[flatten_block_pos];
            default: rgb = rgb;
        endcase
    end
endmodule
