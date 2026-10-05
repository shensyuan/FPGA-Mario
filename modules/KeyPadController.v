module KeyPadController (
    input CLK,
    input [3:0] K_COL,
    output [3:0] K_ROW,
    output [3:0] KEYBOARD,
    output [1:0] COUNT_STATE
);

    wire [15:0] keys;

    reg  [ 3:0] k_row = 4'b0111;
    reg  [18:0] counter;

    reg  [18:0] count_state;

    assign K_ROW = k_row;

    assign KEYBOARD = {keys[8], keys[0], 1'b0, keys[5]};
    assign COUNT_STATE = (keys[15] ? 3 : (keys[11] ? 2 : (keys[7] ? 1 : (keys[3] ? 0 : COUNT_STATE))));

    assign keys[0] = (!K_ROW[3] & !K_COL[3]) | (keys[0] & K_ROW[3]);
    assign keys[1] = (!K_ROW[3] & !K_COL[2]) | (keys[1] & K_ROW[3]);
    assign keys[2] = (!K_ROW[3] & !K_COL[1]) | (keys[2] & K_ROW[3]);
    assign keys[3] = (!K_ROW[3] & !K_COL[0]) | (keys[3] & K_ROW[3]);
    assign keys[4] = (!K_ROW[2] & !K_COL[3]) | (keys[4] & K_ROW[2]);
    assign keys[5] = (!K_ROW[2] & !K_COL[2]) | (keys[5] & K_ROW[2]);
    assign keys[6] = (!K_ROW[2] & !K_COL[1]) | (keys[6] & K_ROW[2]);
    assign keys[7] = (!K_ROW[2] & !K_COL[0]) | (keys[7] & K_ROW[2]);
    assign keys[8] = (!K_ROW[1] & !K_COL[3]) | (keys[8] & K_ROW[1]);
    assign keys[9] = (!K_ROW[1] & !K_COL[2]) | (keys[9] & K_ROW[1]);
    assign keys[10] = (!K_ROW[1] & !K_COL[1]) | (keys[10] & K_ROW[1]);
    assign keys[11] = (!K_ROW[1] & !K_COL[0]) | (keys[11] & K_ROW[1]);
    assign keys[12] = (!K_ROW[0] & !K_COL[3]) | (keys[12] & K_ROW[0]);
    assign keys[13] = (!K_ROW[0] & !K_COL[2]) | (keys[13] & K_ROW[0]);
    assign keys[14] = (!K_ROW[0] & !K_COL[1]) | (keys[14] & K_ROW[0]);
    assign keys[15] = (!K_ROW[0] & !K_COL[0]) | (keys[15] & K_ROW[0]);

    always @(posedge CLK) begin
        counter <= counter + 1;
        if (counter == 0) begin
            k_row = ~k_row >> 1;
            if (k_row == 0) begin
                k_row = 4'b1000;
            end

            k_row = ~k_row;
        end
    end

endmodule
