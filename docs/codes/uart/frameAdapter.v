// This module was designed by kevin
// 
//  frame: (an example)
//  3   2                   1                   0
//  1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0
//  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//  |     0x7E      |                  PRICE                      |
//  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//  |     PRICE     |     0x7F      |           AMOUNT            |
//  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//  |            AMOUNT             |    0x7E     |
//  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// 
//  frame: (a simpler version, THE VERSION THAT THIS MODULE IMPLEMENTED)
//  3   2                   1                   0
//  1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0
//  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//  |     0x7E      |                  PRICE                      |
//  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//  |     PRICE     |                 AMOUNT                      |
//  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//  |    AMOUNT     |    0x7E     |
//  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

//  actually, a 0x7E stands for the start or the end of one frame,
//  first 0x7F accured in the frame means the following part is 
//  the price section, until it comes to an other 0x7F, which indecates 
//  the strat of the amount section.
//  
//  In this file, THE CHARACTER 0x7F BETWEEN PRICE AND AMOUNT IS REMOVED.
//  IT CAN BE ADDED TO THE CODE, PROVIDED, AN EXCELLENT MARK IS WHAT 
//  ATTRACTS YOU.
// 
//  WARNING: 
//    THERE CAN BE AT MOST 4 BYTES IN ONE SECTION: PRICE, AMOUNT, ETC.
//  
//  for EVERY 0x7E in the DATA SECTION and ALIGNED with the one byte,
//  that is, in 31:24, 23:16, 15:8 and 7:0.
//  IT MUST BE REPLACED BY 0x7D 0x5E
//  for EVERY 0x7D in the DATA SECTION
//  IT MUST BE REPLACED BY 0x7D 0x5D
//  
//  NOT IMPLEMENTED:
//  for EVERY 0x7F in the DATA SECTION
//  IT MUST BE REPLACED BY 0x7D 0x5F

module frameSeg(
    input  wire         clk,
    input  wire         rst,
    input  wire [ 7: 0] data,
    input  wire         valid,
    output wire [31: 0] price,
    output wire [31: 0] amount,
    output wire         out_valid
);
    localparam IDLE = 1,
                RECEIVING = 2,
                FINISHED = 4;

    reg  [ 7: 0] frame [15: 0];
    reg  [ 3: 0] stack_top;
    reg          escape;
    reg          not_received;

    reg  [ 7: 0] current_state;
    reg  [ 7: 0] next_state;
    
    always @(posedge clk ) begin
        if(rst)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    always @(*) begin
        if(rst)
            next_state = IDLE;
        else 
            case (current_state)
                IDLE : 
                    next_state = valid && (data=='h7E) ? RECEIVING : IDLE;
                RECEIVING :
                    next_state =    (stack_top==16) ? FINISHED                     : 
                                    valid && (data=='h7E) && ~escape ? FINISHED    :
                                                                                        RECEIVING;
                FINISHED : 
                    next_state = valid && (data=='h7E)? RECEIVING : IDLE;
                default: 
                    next_state = IDLE;
            endcase
    end

    always @(posedge clk ) begin
        if(rst)
            escape <= 0;
        else if(valid && (data=='h7D))
            escape <= 1;
        else if(valid)
            escape <= 0;
    end

    always @(posedge clk ) begin
        if(rst)
            stack_top <= 0;
        else 
            case (current_state)
                IDLE : 
                    stack_top <= 0;
                RECEIVING : 
                    if(valid)
                        stack_top <= (data=='h7D) ? stack_top : stack_top + 1;
                FINISHED : 
                    stack_top <= 0;
                default: 
                    stack_top <= 0;
            endcase
    end

    always @(posedge clk ) begin
        if(valid && (current_state==RECEIVING)) 
            frame[stack_top] <=     escape && (data=='h5D) ? 'h7D :
                                    escape && (data=='h5E) ? 'h7E :
                                                                    data;
    end

    always @(posedge clk ) begin
        if(rst)
            not_received <= 1;
        else if(current_state==FINISHED)
            not_received <= 0;
    end

    assign price = {32{out_valid}} & {frame[0], frame[1], frame[2], frame[3]};
    assign amount = {32{out_valid}} & {frame[4], frame[5], frame[6], frame[7]};
    assign out_valid = (current_state==FINISHED);


endmodule