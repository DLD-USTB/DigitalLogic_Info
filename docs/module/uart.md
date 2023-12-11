# UART与简易电子秤

## 实验目的
在本次实验中，大家将会深入了解一种在设备间交流时如鱼得水的硬件通信协议：Universal Asynchronous Receiver/Transmitter，简称 UART。这不仅是一种硬件通信协议，更像是设备间的无声对话。UART 的独到之处在于它的异步特性——它不需要使用时钟信号连接两个设备，只需靠着 Transmitter（Tx）和 Receiver（Rx）两个信号就能愉快地交换信息。就像在闲聊时无需约定时间一样自在，UART 让设备之间的对话变得轻松而高效。我们将通过本实验，揭秘这种看似简单却大有玄机的通信协议，探索其基本的收发机制。

因此，本实验的目的是学习UART的简单应用；掌握实验平台的外部功能模块在数字系统设计中的应用，以及通信协议的使用。并深入地理解UART协议，并基于UART协议实现一个具有计价、累加与清零功能的简易电子秤。

下面是 UART 收发的波形图，多个输入时钟信号可以产生一个BCLK，而发送的每个数据位为了准确性考量将会持续 16 个BCLK（具体是多少个输入的时钟周期请自行计算，如果你选择使用PLL生成150MHz的时钟信号，你可以查看文档中的表格获取分频系数）。

![波形图](../pic.asset/uart_diag.png)

## 实验内容
1. 参照 UART 手册，以及提供的代码实现一个 UART 收发模块，其端口定义如下：
    ```verilog
    module uartAdapter(
        input  wire         clk    ,
        input  wire         resetn ,
        input  wire         rx     ,
        output wire         tx     ,
        input  wire [ 7: 0] wdata  ,
        input  wire         wvalid ,
        output wire [ 7: 0] rdata  ,
        output wire         rvalid
        );
    ```
    + 该模块包含三个子模块`uart_pll`、`uartTransmitter`和`uartReceiver`。`uartTransmitter`和`uartReceiver`端口定义如下：

    ```verilog
    module uartTransmitter(
        input  wire         clk    ,
        input  wire         rst    ,
        output reg          tx     ,
        input  wire [ 7: 0] wdata  ,
        input  wire         wvalid 
    );
    
    module uartReceiver(
        input  wire         clk    ,
        input  wire         rst    ,
        input  wire         rx     ,
        output wire [ 7: 0] rdata  ,
        output reg          rvalid
    );
    ```
    + uartAdapter模块需要做到如下要求：

      - **16** 倍过采样
      - 波特率 **19200**
      - **8** 个数据位
      - **无**奇偶校验位
      - **1** 位停止位
      - 滤波（如实现接收功能可以考虑）
      - 在wvalid为高时，接收此时的wvalid并通过tx输出
      - 在你完成一次传输时，将收到的数据通过rdata传出，并拉高rvalid一周期

    + 当然，从零开始实现一个UART收发模块的难度对于大家可能会略有些高。为了让大家在能够深入理解UART协议的同时，不用花太多的时间在写各种琐碎而基础的代码或是与UART无关错误的debug上，在收到了若干同学提出的宝贵建议后，我们决定**将本次实验所用到的UART收发模块的参考代码直接提供给大家**，大家如果不愿意从零写起，直接使用我们给出的代码即可。
    + 备注：
      1. 大家在使用我们提供的参考代码中的模块时，可能会发现缺少了一些相关代码，这可能是我们~~有意为之~~*不小心删除的*，请大家根据对UART的理解自行填补。
      2. 大家在填补完成代码后，可能会发现，虽然填补的代码理论上应当是完全正确的，但该收发模块并不能正常工作。这~~亦是我们有意为之~~*可能是我们不小心写错的*，请大家根据对UART的理解，从代码中找到粗心的我们留下的错误，并将其改正。
      3. 这些要求与提供的资料是基本对应的，因此可以大大简化难度。
      4. 我们在提供的`UART_Receiver.v`中部分实现性能~~不小心~~变差了，如果**有能力以及相关意愿**可以**尝试**更改。（我们推荐对龙芯杯有兴趣的同学尝试，经过修改，整体的**W**orst **N**egative **S**lack（WNS）会大幅降低。经测试，在150MHz时钟下至少可以做到WNS为1.960）
     

2. 通过已给出的外设控制模块使用正确的UART收发模块，完成上板通信测试。

    + 当然，从零开始实现一个外设控制模块的难度对于大家可能会略有些高。为了让大家在能够深入理解UART协议的同时，不用花太多的时间在写各种琐碎而基础的代码或是与UART无关错误的debug上，我们决定**提供简化版本的帧接收器**，大家如果不愿意从零写起，直接使用我们给出的模块即可。
    + 备注：
        + 如果想详细了解帧这个概念，可以自行搜索。
        + 通过尝试使用串口令电脑与EGO1进行通信。文件包中提供了指令序列。
        + 设计具有开放性，鼓励设计实现自己的输入输出控制逻辑和显示效果。也可自行实现帧协议，或补全提供文件中的帧协议。


3. 实现简易电子秤

    实现一个具有基础功能的电子秤，具体要求如下：

    + 该电子秤能通过UART协议接收使用电脑的串口传输软件（例如我们提供的XCOM）传输而来的数据，并将其存储。
    + 该电子秤具有帧解析功能，能够解析通过UART协议接收的数据，并将其存储。
    + 该电子秤具有计算本次价格与累计价格的功能，并将其显示在数码管上。例如：本次为第3次输入累加，单价为3，质量为2，历史总价为20，则数码管可以显示：“AC03 0026”（总输入次数与总价）。按下某个按键后，数码管的显示内容切换为：“0302 0006”（本次的单价、质量与价格）。
    +
    ?>  当然，以上只是一个简单的示范。根据我们提供的帧格式，你可以使用最大4个字节来存储单价和质量，而以上的示例只能支持显示一些小得可怜的计算。而且，又有哪个电子秤是以元为最小单位的呢？我们希望你们能实现定点小数的输入与计算功能，例如单价是12.34，质量是11.11，那么输出的本次价格为137.10（四舍五入至2位小数）。具体如何实现，答案在你们的创造力中。

    + 该电子秤具有清零功能，按下清零键后，一切恢复如初。数码管应有对应信息输出，例如“CLR”。
    + 该电子秤能在每次输入次数或总价发生改变时（包括清零）通过UART向电脑端发送数据，数据包括输入次数、单价、质量、本次价格、总价。电脑端解析该数据，并将其输出在电脑屏幕上。
    +
    ?> 然而如果只是单纯地输出数据的话，未免有些过于朴素了。以要求3中的第一个例子来说，如果只是输出“AC03 0026 0302 0006”的话，可以说是毫无可读性。我们希望你们能通过整齐的格式给出完整的信息。一位助教Kevin给出的输出例子是：

    ```
        **********Vanity Fair's Balance**********
        price: 12.34$
        amount: 56
        ---accumulate mode begin---
        price: 12.34$
        amount: 56
        price: 12.34$
        amount: 56
        ---accumulate mode end---
        total: xx.xx$
        **********Vanity Fair's Balance**********
    ```
    + 
    ?> 很遗憾我的文学素养并不高，无法为大家解释“Vanity Fair's Balance”是什么（补充：Vanity Fair译为名利场，源于班扬的《天路历程》，Balance事实上是天平。——Kevin）。但无论怎样，像以上这样具有较高可读性的输出格式比“AC03 0026 0302 0006”要好太多不是吗？具体的输出格式实现，大家可以自由发挥。

+ 为你的电子秤增加更多功能


?> 实验4.1所实现的只是一些最基础的要求（虽然这并不意味着难度也很低）。在本实验中，我们希望你们能为你们的电子秤添加更多功能，例如可变长数据帧、去皮、大数显示优化（例如2000012.34可以简略显示为2M，你可以选择的字头有k,M,G,T,P等）、多个可切换的历史总价、撤销功能等。具体添加什么功能，我们不作约束。




## 实验要求
1. 在实验报告中提交系统级设计模块图、设计代码、激励程序（不必须包含所有模块的）、仿真波形结果截图（与激励配套）、板级实测验证结果照片。其中，系统级设计模块图要求给出整个系统的数据输出信号，系统内各个子模块的输入输出信号和模块间的连接关系（不需要画出数码管/LED灯/按键等，给出其信号名及位宽即可）。


2. 提交实验报告和所有源程序文件的压缩包。


  
## 附录 A

### 代码及IP
[UART Receiver.v](codes/uart/UART_Receiver.v ':ignore ')

[UART Transmitter.v](codes/uart/UART_Transmitter.v ':ignore ')

[Frame Adapter.v](codes/uart/frameAdapter.v ':ignore ')

### 相关软件
[XCOM.exe](codes/uart/XCOM_V2.6.exe ':ignore ')

[XCOM配置文件（流水学号）](codes/uart/UART_TEST.ini ':ignore ') 

### UART规范
![格式](../pic.asset/uart_form.png)

![分频表](../pic.asset/uart_clk_divisor.png)

[KeyStone Architecture Literature Number: SPRUGP1 Universal Asynchronous Receiver/Transmitter (UART) User Guide](appendix/uart_doc.pdf ':ignore ')

### UART模块框图
![顶层模块框图](../pic.asset/uart.svg)

### 控制协议及相关说明
frame: (an example)
```
3   2                   1                   0
1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|     0x7E      |                  PRICE                      |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|     PRICE     |     0x7F      |           AMOUNT            |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|             MOUNT             |    0x7E     |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```
```
frame: (a simpler version, THE VERSION THAT THIS MODULE IMPLEMENTED)
3   2                   1                   0
1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|     0x7E      |                  PRICE                      |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|     PRICE     |                 AMOUNT                      |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|     MOUNT     |    0x7E     |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

Actually, a 0x7E stands for the start or the end of one frame, first 0x7F accured in the frame means the following part is the price section, until it comes to an other 0x7F, which indecates the strat of the amount section.

In this file, THE CHARACTER 0x7F BETWEEN PRICE AND AMOUNT IS REMOVED. IT CAN BE ADDED TO THE CODE, PROVIDED, AN EXCELLENT MARK IS WHAT ATTRACTS YOU.

!> THERE CAN BE AT MOST 4 BYTES IN ONE SECTION: PRICE, AMOUNT, ETC.

for EVERY 0x7E in the DATA SECTION and ALIGNED with the one byte,  that is, in 31:24, 23:16, 15:8 and 7:0. IT MUST BE REPLACED BY 0x7D 0x5E 
for EVERY 0x7D in the DATA SECTION IT MUST BE REPLACED BY 0x7D 0x5D

NOT IMPLEMENTED:
for EVERY 0x7F in the DATA SECTION IT MUST BE REPLACED BY 0x7D 0x5F

接收端将会按照以上规则进行处理，因此在发送时，请注意发送的信息*有时需要进行转义*。
