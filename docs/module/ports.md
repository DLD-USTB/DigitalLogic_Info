# 顶层模块与端口映射

> by NginW

## 写在前面



实验完成之，为了能够让大家更好的理解实验中各个模块的实现细节，也是为了现在依旧没有验收的同学能够完成验收，助教会给实验写个简单的文档，对实验做一个简单的分析。如有错漏之处，欢迎同学们在评论区指正。写完代码之后，点击rtl仿真，得到rtl图如下图所示：

![image-20211123224510884](pic.asset/image-20211123224510884.png)



## 模块的功能

第一个流水灯实验中，用到了三个模块，led控制模块led_ctl，计数器模块counter和顶层模块led_top,led_ctl和counter作为具体的功能模块,能够硬件功能,top模块作为电路设计的顶层,完成模块的连接,对外暴露引脚端口的功能.

### top

top模块的端口定义如下,top有三个外部输入端口input和一个16位宽的输出端口led,这些端口就代表我们设计的电路和外部实际的硬件资源连接的引脚.说明top模块接收来自外部的三个输入,输出一个16位宽度的信号

```verilog
module flash_led_top(
        input clk,
 	 	input rst_n,
 	 	input sw0,
 	 	output [15:0]led
);
```

然后,在top内部,分别对之前编写完成的两个模块进行了一次实例化,并提供了相应的输入,输出驱动信号.同时,观察可以得出,`counter`的输出信号`clk_bps`同时又作为了`led_ctl`的输入信号.这表明了top模块的另外一个作用,指定信号,将各个独立的模块,通过信号连接起来,形成一个整体.

在定义各个模块的时候,实际上只是定义了模块的输入,输出方向,数据宽度和类型,并没有指明具体的信号从何而来(类似于c++中的函数概念,但又不同).顶层模块top的作用,就是提供模块所需的具体信号驱动,达到想要实现的功能.

```verilog
module flash_led_top(
        input clk,
 	 	input rst_n,
 	 	input sw0,
 	 	output [15:0]led
 	 	);
 	 	wire clk_bps;
 	 	wire rst;
 	 	assign rst = ~rst_n;
 	 	
 	 	counter counter(
 	 		.clk( clk ),
 	 		.rst( rst ),
 	 		.clk_bps( clk_bps )
 	 	);
 	 	flash_led_ctl flash_led_ctl(
 	 		.clk( clk ),
 	 		.rst( rst ),
 	 		.dir( sw0 ),
 	 		.clk_bps( clk_bps ),
 	 		.led( led )
 	 	);
endmodule
```

### counter

counter是计数器模块,因为使用的开发板上的时钟频率太高,如果直接使用时钟的频率,由于视觉暂留效应,会让led看上去全部点亮,无法实现流水灯的效果.所以需要分频,得到一个适当的频率.

counter模块的功能非常简单,它设置了两个计数器`first`和`second`.当开发板上的时钟上升沿时,触发计数器,如果`first`小于1w,则将`first`加一,等于1w则清零.

第二个计数器依赖于第一个计数器,它加一条件,除了本身`second`小于1w以外,还需要`first`等于1w,才会加一,因为`first`加一之后会在下一个时钟周期清零,所以`second`两次加一之间,间隔为`first`从0加到1w需要的时间.

```verilog
module counter(
  input clk,
  input rst,
  output clk_bps
);
  reg [13:0] counter_first,counter_second;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      counter_first <= 14'b0;
    end
    else begin
      if (counter_first == 14'd10000) begin
        counter_first <= 14'b0;
      end
      else begin
        counter_first <= counter_first +1;
      end
    end
  end

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      counter_second <= 14'b0;
    end
    else  begin      
      if (counter_second == 14'b10000) begin
        counter_second <= 14'b0;
      end
      else begin
        if (counter_first == 14'b10000) 
          counter_second <= counter_second + 1;
      end
    end
  end

  assign clk_bps = counter_second == 14'b10000;

endmodule
```



## QA

