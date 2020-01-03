# RISC-V CPU report

by 刘成锴

## 实现过程

在实现过程中，我主要参考了《自己动手写CPU》，在书的基础上首先实现了ALU指令（logic & shift），之后实现了jump、branch指令。

由于访问内存和处理structure hazard有难点，所以我先通过自己构造数据，设计顶层模块，实现了4字节取指令，确保自己的ALU指令和跳转指令、分支指令是正确的。

之后我重新设计了if阶段和mem阶段，处理了structure hazard，初步完成了项目。

## 设计思路

### 取指令 IF

由于访问内存一次只能1个byte，所以我的取指令设计是6周期取指令。

1. 发地址
2. 发地址
3. 发地址，收数据
4. 发地址，收数据
5. 收数据
6. 收数据，得到完整指令

structure hazard的情况后面说明。

## i-cache

在icache模块中，实现了Instruction cache，是一个1KB直接映射的cache。

当IF阶段6周期取到指令时，第六周期向icache模块发送取到的指令和相应地址，inst和addr将在下一周期写入icache。

当添加了icache后，IF的第一周期发送地址，如果cache hit后，第二周期收到指令，取指完成，不用再发送地址，pc寄存器加4，下周期可以取下一条指令。

## 分支预测

如果不分支预测，branch指令将在ID阶段对比rs和rt的值判断是否跳转。

动态分支预测的branch history table通过128个2位饱和计数器实现。当前pc值模128得到计数器编号。

在下一周期，由ID阶段发送信息判断预测是否正确，并调整计数器值。若预测错误，具体情况在control hazard说明。

## Load/Store

Mem阶段load需要3/4/6周期，store需要2/3/5周期。

## d-cache

在dcache模块中，实现了data cache，是一个1KB直接映射的cache，采取write through策略。

当LW或SW指令完成后，会将data和相应addr写入dcache。

添加了dcache后，实现了2周期load。

## 创新之处

## 难点