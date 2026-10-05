module MapParser (
    input CLK,
    input RST_N,
    input [7:0] MAP_INDEX,
    input [9:0] RENDER_X,
    input [9:0] RENDER_Y,
    input [9:0] PLAYER_X,
    input [9:0] PLAYER_Y,
    output [3:0] BLOCK_TYPE,
    output [9:0] LIMIT_U_POS,
    output [9:0] LIMIT_D_POS,
    output LIMIT_L,
    output LIMIT_R,
    output [23:0] COIN_COUNT
);
    reg [14:0] MAP_DATA[20 * `MAP_LENGTH];
    reg [14:0] ORIGIN_MAP_DATA[20 * `MAP_LENGTH];

    reg [16:0] GOLD_MAP_DATA[`GOLD_LENGTH];
    reg GOLD_STATE_DATA[`GOLD_LENGTH];

    reg [16:0] BRICK_MAP_DATA[`BRICK_LENGTH];
    reg [1:0] BRICK_STATE_DATA[`BRICK_LENGTH];
    reg [16:0] current_brick;


    reg [3:0] next_block_type;

    wire [4:0] block_x = RENDER_X >> `TO_BLOCK_SHIFT;
    wire [4:0] block_y = RENDER_Y >> `TO_BLOCK_SHIFT;
    wire [4:0] next_block_x = (RENDER_X + 1) >> `TO_BLOCK_SHIFT;

    wire [4:0] player_block_x;
    wire [4:0] player_block_y;
    wire player_x_inblock;
    wire player_y_inblock;

    wire [16:0] player_upper_block_id;
    assign player_upper_block_id[16:12] = player_block_x;
    assign player_upper_block_id[11:8]  = player_block_y - 1;
    assign player_upper_block_id[7:0]   = MAP_INDEX;
    wire [16:0] player_upper_block_id_2;
    assign player_upper_block_id_2[16:12] = player_block_x + 1;
    assign player_upper_block_id_2[11:8]  = player_block_y - 1;
    assign player_upper_block_id_2[7:0]   = MAP_INDEX;

    wire [14:0] current_blocks = MAP_DATA[20*MAP_INDEX+block_x];

    wire [16:0] next_block_id;
    assign next_block_id[16:12] = next_block_x;
    assign next_block_id[11:8]  = block_y;
    assign next_block_id[7:0]   = MAP_INDEX;

    reg [23:0] coin_count = 0;
    assign COIN_COUNT = coin_count;

    integer i;

    assign BLOCK_TYPE = current_blocks[block_y] ? (RENDER_Y >= `GROUND ? 4'd1 : next_block_type) : 4'd0;

    Collision collision (
        .PLAYER_X(PLAYER_X),
        .PLAYER_Y(PLAYER_Y),
        .MAP_DATA_0(MAP_DATA[20*MAP_INDEX+player_block_x-1]),
        .MAP_DATA_1(MAP_DATA[20*MAP_INDEX+player_block_x]),
        .MAP_DATA_2(MAP_DATA[20*MAP_INDEX+player_block_x+1]),
        .MAP_DATA_3(MAP_DATA[20*MAP_INDEX+player_block_x+2]),
        .LIMIT_U_POS(LIMIT_U_POS),
        .LIMIT_D_POS(LIMIT_D_POS),
        .LIMIT_L(LIMIT_L),
        .LIMIT_R(LIMIT_R),
        .PLAYER_BLOCK_X(player_block_x),
        .PLAYER_BLOCK_Y(player_block_y),
        .PLAYER_X_INBLOCK(player_x_inblock),
        .PLAYER_Y_INBLOCK(player_y_inblock)
    );

    initial begin
        $readmemh("map/Main.hex", ORIGIN_MAP_DATA);
        $readmemh("map/Gold.hex", GOLD_MAP_DATA);
        $readmemh("map/Brick.hex", BRICK_MAP_DATA);
    end

    always @(negedge RST_N or posedge player_y_inblock) begin
        if (!RST_N) begin
            coin_count = 0;

            // Reset Map
            for (i = 0; i < 20 * `MAP_LENGTH; i = i + 1) MAP_DATA[i] <= ORIGIN_MAP_DATA[i];

            for (i = 0; i < `GOLD_LENGTH; i = i + 1) GOLD_STATE_DATA[i] = 0;

            for (i = 0; i < `BRICK_LENGTH; i = i + 1) begin
                current_brick = BRICK_MAP_DATA[i];

                BRICK_STATE_DATA[i] = 2;
                MAP_DATA[20*current_brick[7:0]+current_brick[16:12]][current_brick[11:8]] = 1;
            end
        end else if (PLAYER_Y == LIMIT_U_POS) begin
            for (i = 0; i < `GOLD_LENGTH; i = i + 1) begin
                if (GOLD_STATE_DATA[i] == 0) begin
                    if ((player_upper_block_id == GOLD_MAP_DATA[i]) || (!player_x_inblock && player_upper_block_id_2 == GOLD_MAP_DATA[i])) begin
                        GOLD_STATE_DATA[i] = 1;
                        coin_count = coin_count + 1;
                    end
                end
            end

            for (i = 0; i < `BRICK_LENGTH; i = i + 1) begin
                current_brick = BRICK_MAP_DATA[i];

                if (((player_upper_block_id == BRICK_MAP_DATA[i]) || (!player_x_inblock && player_upper_block_id_2 == BRICK_MAP_DATA[i]))) begin
                    BRICK_STATE_DATA[i] = BRICK_STATE_DATA[i] != 0 ? BRICK_STATE_DATA[i] - 1 : 0;
                end

                MAP_DATA[20*current_brick[7:0]+current_brick[16:12]][current_brick[11:8]] = (BRICK_STATE_DATA[i] != 0);
            end
        end
    end

    always @(posedge CLK) begin
        next_block_type = 4'd2;
        for (i = 0; i < `GOLD_LENGTH; i = i + 1) begin
            if (next_block_id == GOLD_MAP_DATA[i]) next_block_type = 4'd3 + GOLD_STATE_DATA[i];
        end

        for (i = 0; i < `BRICK_LENGTH; i = i + 1) begin
            if (next_block_id == BRICK_MAP_DATA[i]) next_block_type = 4'd5;
        end
    end

endmodule
