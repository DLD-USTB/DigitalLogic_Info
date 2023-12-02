module uartReceiver(
    input  wire         clk    ,
    input  wire         rst    ,
            
    input  wire         rx     ,

    output wire [ 7: 0] rdata  ,
    output reg          rvalid
);


    reg [ 8: 0] divider_1;

    reg [ 4: 0] state;
    reg [ 4: 0] next_state;
    reg [ 7: 0] locker_rdata;
    reg         rx_delay;

    reg [ 4: 0] read_counter;
    reg [15: 0] first_counter;
    reg [399:0] filter_buffer;
    reg [10: 0] ones_counter;

    wire        discard_is_one;
    wire        add_is_one;

    reg [ 3: 0] cnt = 0;

    integer i;
    always @(*) begin
        ones_counter = 'd0;
        for(i=0;i<400;i=i+1)begin
            ones_counter = ones_counter + filter_buffer[i];
        end
    end

    wire        b_clk;
    wire        s_clk;
    wire        read_start;
    wire        rx_filtered;

    assign b_clk = (divider_1=='d485);
    assign s_clk = (read_counter=='d16);
    assign rdata = locker_rdata;

    always @(posedge clk ) begin
        if(rst) begin
            filter_buffer <= {400{1'b1}};
        end else begin
            filter_buffer <= {filter_buffer[398:0],rx};
        end
    end

    assign rx_filtered = (ones_counter > 'd350) ? 'd1 : 'd0;

    assign read_start = ;

    always @(posedge clk ) begin
        if(rst || (divider_1=='d485) || read_start) begin
            divider_1 <= 'd0;
        end else begin
            divider_1 <= divider_1 + 'd1;
        end 
    end

    always @(posedge clk ) begin
        if(rst || (first_counter=='d3888))begin
            first_counter <= 'd0;
        end else if(read_start)begin
            first_counter <= 'd1;
        end else if(first_counter != 'd0)begin
            first_counter <= first_counter + 'd1;
        end
    end

    always @(posedge clk ) begin
        if(rst)
            rx_delay <= 'd0;
        else 
            rx_delay <= rx;
    end


    always @(posedge clk ) begin
        if(rst | s_clk | (first_counter=='d3888))
            read_counter <= 'd0;
        else if(b_clk)
            read_counter <= read_counter + 'd1;
        else if(b_clk)
            read_counter <= 'd0;
    end

    always @(posedge clk ) begin
        if(rst || (rvalid && s_clk))
            cnt <= 'd0;
        else if((state==READ) && (cnt!='d7))
            cnt <= cnt + 'd1;
        else if((cnt=='d7) && s_clk)
            cnt <= 'd0;
        else if(s_clk)
            cnt <= 'd0;
    end


endmodule //uartReceiver
