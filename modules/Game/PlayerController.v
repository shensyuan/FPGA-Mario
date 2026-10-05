module PlayerController (
    input CLK,
    input RST_N,
    input [3:0] KEYBOARD,
    input [9:0] LIMIT_U_POS,
    input [9:0] LIMIT_D_POS,
    input LIMIT_L,
    input LIMIT_R,
    output [9:0] PLAYER_X,
    output [9:0] PLAYER_Y,
    output DIRECTION,
    output WALKING,
    output WALKING_ANIMATION,
    output [7:0] MAP_INDEX,
    output [23:0] DEATH_COUNT
);
    // Player position
    reg  [ 9:0] x_pos = 10'd72;
    reg  [ 9:0] y_pos = `GROUND - (`BLOCK_HEIGHT << 1);
    reg  [ 7:0] map_index = 8'd0;
    reg  [23:0] death_count = 0;

    reg         x_overflow = 0;

    reg  [31:0] y_speed = 32'd0;  // Y-axis speed

    reg         direction = 1;  // Move direction, 1 for right
    reg         walking_animation = 0;  // Animation state

    reg         can_jump = 1;  // Whether player can jump
    reg         jump_2 = 0;  // Whether player can jump
    reg         walking = 0;  // Whether player is walking

    reg  [22:0] timer_x = 23'd0;  // Timer of trigger x-axis movement
    reg  [22:0] timer_y = 23'd0;  // Timer of trigger y-axis movement
    reg  [25:0] gforce_timer = 26'd0;  // Timer of gravity update
    reg  [25:0] y_pos_timer = 26'd0;  // Timer of y-axis position update
    reg  [25:0] walking_timer = 26'd0;  // Timer of walking animation switch

    wire [ 9:0] on_ground_pos;

    assign PLAYER_X = x_pos;
    assign PLAYER_Y = y_pos;
    assign DIRECTION = direction;
    assign WALKING = walking;
    assign WALKING_ANIMATION = walking_animation;
    assign MAP_INDEX = map_index;
    assign DEATH_COUNT = death_count;

    task reset;
        input reset_life;
        begin
            x_pos = 10'd72;
            y_pos = `GROUND - (`BLOCK_HEIGHT << 1);
            map_index = 0;
            if (reset_life) death_count = 0;

            y_speed = 0;

            timer_x <= 0;
            timer_y <= 0;
            gforce_timer <= 0;
            y_pos_timer <= 0;
            walking_timer <= 0;
        end
    endtask

    always @(posedge CLK or negedge RST_N) begin
        if (!RST_N) begin
            reset(1);
        end else begin
            // If player press one of left or right key
            if (KEYBOARD[2] ^ KEYBOARD[3]) begin
                // Set state to is walking
                walking <= 1;
                walking_timer <= walking_timer + 1;

                // Update timer and direction
                timer_x <= (KEYBOARD[2] ^ direction) ? timer_x + 1 : 23'd0;
                direction <= KEYBOARD[3];
            end else begin
                // If no key is pressed, reset state amd timer
                walking <= 0;
                walking_timer <= 0;
                walking_animation <= 0;

                // Speed up first interval
                timer_x <= `KEYBOARD_TIMER >> 1;
            end

            // Press long enough to trigger walking animation switch
            if (walking_timer == `WALKING_TIMER) begin
                walking_timer <= 0;
                walking_animation <= ~walking_animation;
            end

            // Press long enough to trigger movement
            if (timer_x == `KEYBOARD_TIMER) begin
                timer_x <= 0;

                if ((!LIMIT_R & direction) || (!LIMIT_L & !direction))
                    x_pos = direction ? x_pos + 1 : x_pos - 1;
            end

            // Check if need to change map
            if (x_pos == 640 - (`BLOCK_WIDTH >> 1) - 6 || x_pos == 10'd1023) begin
                map_index = x_pos == 10'd1023 ? map_index - 1 : map_index + 1;

                x_pos = (x_pos == 10'd1023) ? 640 - (`BLOCK_WIDTH >> 1) - 7 : 0;
                y_pos = `GROUND - `BLOCK_HEIGHT;

                map_index = (map_index == 8'd255) ? `MAP_LENGTH - 1 : (map_index == `MAP_LENGTH ? 0 : map_index);
            end

            // If player press jump and player can jump
            if (KEYBOARD[0] && (can_jump || jump_2)) begin
                timer_y <= timer_y + 1;
            end else begin
                // Reset can jump if player not press jump and player on the ground
                can_jump <= !KEYBOARD[0] && y_pos == LIMIT_D_POS;
                jump_2   <= 0;

                // Speed up first interval
                timer_y  <= 0;
            end

            // Trigger a small jump
            if (timer_y == `JUMP_TIMER && can_jump) begin
                can_jump <= 1'b0;
                jump_2   <= 1'b1;
                y_speed = `JUMP_FORCE;
            end

            // Press long enough to trigger bigger jump
            if (timer_y == `JUMP_TIMER_2 && jump_2) begin
                timer_y <= 0;

                jump_2  <= 1'b0;
                y_speed = y_speed + `JUMP_FORCE_2;
            end

            // ========== Gravity simulation ==========
            // If player above the ground
            if (y_pos < LIMIT_D_POS) begin
                if (timer_y == 0 || jump_2 || timer_y[1:0] == 2'b10)
                    gforce_timer <= gforce_timer + 1;
                if (gforce_timer == `GFORCE_TIMER) begin
                    gforce_timer <= 0;
                    y_speed = y_speed - `GFORCE;
                end
            end else gforce_timer <= 0;

            // ========== Accelerate simulation ==========
            y_pos_timer <= y_pos_timer + 1;
            if (y_pos_timer == `Y_POS_TIMER) begin
                y_pos_timer <= 0;

                // If player under the ground
                if (y_pos - y_speed > LIMIT_D_POS) begin
                    y_pos   = LIMIT_D_POS;
                    y_speed = 0;
                end else if (y_pos - y_speed < LIMIT_U_POS) begin
                    timer_y <= 0;
                    y_pos   = LIMIT_U_POS;
                    y_speed = 0;
                    jump_2 <= 0;
                end else y_pos = y_pos - y_speed;

                if (y_pos > `GROUND + (`BLOCK_HEIGHT << 1)) begin
                    death_count = death_count + 1;
                    reset(0);
                end
            end
        end
    end
endmodule
