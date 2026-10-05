module DotMatrix_Output (
    input CLK,
    input IS_WALK,
    input REVERSE,
    output [7:0] ROW,
    output [15:0] COL
);
    reg [15:0] counter;
    reg [21:0] img_counter;
    reg [1:0] img_state = 0;
    // reg [7:0] IMG_DATA[8];
    // reg [7:0] NUM_0[8];
    // reg [7:0] NUM_1[8];
    // reg [7:0] NUM_2[8];
    // reg [7:0] NUM_3[8];
    // reg [7:0] NUM_4[8];
    // reg [7:0] NUM_5[8];
    // reg [7:0] NUM_6[8];
    // reg [7:0] NUM_7[8];
    // reg [7:0] NUM_8[8];
    // reg [7:0] NUM_9[8];
    reg [7:0] STOP[8];
    reg [7:0] WALK[8];

    assign ROW = ~(8'b1 << (7 - counter[15:13]));
    // assign COL = 0;
    // assign COL[7:0] = WALK[counter[15:13]];
    assign COL[15:8] = IS_WALK ? (REVERSE ? WALK[7 - counter[15:13]] : WALK[counter[15:13]]) : STOP[counter[15:13]];

    initial begin
        $readmemb("dot_matrix_image/stop.hex", STOP);
        $readmemb("dot_matrix_image/walk.hex", WALK);
        // $readmemb("dot_matrix_image/heart.hex", IMG_DATA);
        // $readmemb("dot_matrix_image/0.hex", NUM_0);
        // $readmemb("dot_matrix_image/1.hex", NUM_1);
        // $readmemb("dot_matrix_image/2.hex", NUM_2);
        // $readmemb("dot_matrix_image/3.hex", NUM_3);
        // $readmemb("dot_matrix_image/4.hex", NUM_4);
        // $readmemb("dot_matrix_image/5.hex", NUM_5);
        // $readmemb("dot_matrix_image/6.hex", NUM_6);
        // $readmemb("dot_matrix_image/7.hex", NUM_7);
        // $readmemb("dot_matrix_image/8.hex", NUM_8);
        // $readmemb("dot_matrix_image/9.hex", NUM_9);
    end

    always @(posedge CLK) begin
        counter = counter + 1;
    end

endmodule
