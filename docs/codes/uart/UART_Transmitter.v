module uartTransmitter(
    input  wire         clk    ,
    input  wire         rst    ,
            
    output reg          tx     ,

    input  wire [ 7: 0] wdata  ,
    input  wire         wvalid 
);

    reg [ 8: 0] divider_1;
    reg [ 7: 0] locker_wdata;
    reg         locker_wvalid;
    reg         wvalid_delay;
    reg [ 4: 0] write_counter;
    reg [ 3: 0] cnt;
    reg         wdone;

    wire        b_clk;
    wire        s_clk;
    
    assign b_clk = (divider_1=='d485);
    assign s_clk = ;

    always @(posedge clk ) begin
        wvalid_delay <= wvalid;
    end


    always @(posedge clk)begin
        if(rst) 
            locker_wdata <= 'd0;
        else if(~wvalid & wvalid_delay)
            locker_wdata <= wdata; 
    end

    always @(posedge clk)begin
        if(rst) 
            locker_wvalid <= 'd0;
        else if(wvalid & wvalld_delay)
            locker_wvalid <= 'd1; 
        else if(wdone)
            locker_wvalid <= 'd0;
    end

    always @(posedge clk ) begin
        if(rst | (write_counter=='h10))
            write_counter <= 'd0;
        else if(s_clk)
            write_counter <= 'd1;
        else if(b_clk)
            write_counter <= 'd0;
    end

    always @(posedge clk ) begin
        if(rst) 
            divider_1 <= 'd0;
        else 
            divider_1 <= divider_1 + 'd1;
    end

    always @(posedge clk ) begin
        if(rst || (wdone && s_clk))
            cnt <= 'd0;
        else if((cnt!='d9) && s_clk)
            cnt <= cnt + 'd1;
        else if((cnt=='d9) && s_clk)
            cnt <= 'd0;
        else if(s_clk)
            cnt <= 'd0;
    end

    always @(posedge clk ) begin
        if(rst) begin
            tx <= 'd1;
        end else if(s_clk)begin
            case (cnt)
                'd0 :  
                    tx <= 'd0; // start
                'd1, 'd2, 'd3, 'd4, 'd5, 'd6, 'd7, 'd7: // data
                    tx <= locker_wdata[cnt-'d1];
                'd8 : // stop
                    tx <= 'd1;
                default: 
                    tx <= 'd1;
            endcase
        end else if(s_clk)begin
            tx <= 'd1;
        end 
    end

    always @(posedge clk)begin
        if(rst)
            wdone <= 'd0;
        else if((cnt=='h10) && (s_clk))
            wdone <= 'd1;
    end

endmodule //uartSender
