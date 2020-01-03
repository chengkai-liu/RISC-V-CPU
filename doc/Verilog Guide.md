# Verilog Guide by 刘成锴

## Reference

夏宇闻 《Verilog经典教程》

页号为《Verilog经典教程》中的相应页号。

```bash
$ iverilog -o <output-file> <source-file-1> <source-file-2> ... // 编译
$ vvp <executable-verilog-file> // 执行
```

---

## 2.4 Verilog中模块的结构 P22

```verilog
module <模块名> (
		<端口>
  	<端口>
  	......
);
  	<端口定义>
  //input为输入端口
  //output为输出端口
  //inout为双向端口
  	<数据类型说明>
  //reg a; 定义信号a的数据类型为reg型
  //wire[31:0] out; 定义信号out的数据类型为32位wire型
  	<逻辑功能描述>
endmodule
```

```verilog
// 一个实现32位加法器的模块，有两个输入信号in1、in2，两者相加的结果通过out输出
mode add32(in1, in2, out);

	input in1, in2;	//端口定义，此处是输入端口
	output out; //端口定义，此处是输出端口

	wire[31 : 0] in1, in2, out; //数据类型说明，此处都是wire型
	assign out = in1 + in2;

endmodule
```

---

## 2.5 Verilog基本元素 P24

### 2.5.1 常量 P24

格式：<位宽> ' <进制> <数字>

### 2.5.2 变量声明与数据类型 P24

#### 1. net型变量

#### 2. variable型变量

### 2.5.3 向量 P26

[MSB : LSB]

### 2.5.4 运算符 P26

---

##  2.6 Verilog行为语句 P29

### 2.6.1 过程语句 P29

Verilog定义的模块一般包括过程语句，过程语句有两种：initial, always。其中initial用于仿真中的初始化，其中的语句只执行一次。而always中的语句则是不断重复执行的。

#### 1. always过程语句 P29

```verilog
always @(<敏感信号表达式>)
  begin
    //语句序列
  end
```

>```verilog
>组合逻辑：always @(*)	用阻塞性赋值
>  时序逻辑：always @(posedge clk)	用非阻塞性赋值
>```
>
>* Combinational: `always @(*)`
>* Clocked: `always @(posedge clk)`

#### 2. intial过程语句 P30

```verilog
initial
  begin
    //语句序列
  end
```



### 2.6.2 赋值语句 P31

>wire只能被assign连续赋值，reg只能在initial和always中赋值。wire使用在连续赋值语句中，而reg使用在过程赋值语句中。

赋值语句有两种：持续赋值语句、过程赋值语句

#### 1. 持续赋值语句

assign为持续赋值语句，主要用于对**wire**型变量的赋值

#### 2. 过程赋值语句

##### 1. 非阻塞赋值（Non-Blocking）
b <= a

非阻塞赋值**在整个过程语句结束时**才会完成赋值操作，即b的值并不是立刻改变的。

##### 2. 阻塞赋值（Blocking）

b = a

阻塞赋值**在该语句结束时就立即完成**赋值操作。

---

> **在组合always块中，使用阻塞性赋值。在时序always块中，使用非阻塞性赋值。**具体为什么对设计硬件用处不大，还需要理解Verilog模拟器如何跟踪事件(译者注：的确是这样，记住组合用阻塞性，时序用非阻塞性就可以了)。不遵循此规则会导致极难发现非确定性错误，并且在仿真和综合出来的硬件之间存在差异。
>
> In a **combinational** always block, use **blocking** assignments. In a **clocked** always block, use **non-blocking** assignments. A full understanding of why is not particularly useful for hardware design and requires a good understanding of how Verilog simulators keep track of events. Not following this rule results in extremely hard to find errors that are both non-deterministic and differ between simulation and synthesized hardware.

---

### 2.6.3 条件语句 P32

条件语句有if-else、case两种，**应放在always块内**。

### 2.6.4 循环语句 P34

Verilog中存在四种类型的循环语句：for、forever、repeat、while。

### 2.6.5 编译指示语句 P35

#### 1. 宏替换`define

`define可以用一个简单的名字或有意义的表示（也称为宏名）代替一个复杂的名字或变量。

``` verilog
`define 宏名 变量或名字
```

#### 2. `include语句

`include是文件包含语句，它可将一个文件全部包含到另一个文件中。

```verilog
`include "文件名"
`include "defines.v"
```

#### 3. 条件编译语句\`ifdef, \`else, `endif

### 2.6.6 行为语句的可综合性

有些语句是不可综合的，也就是说综合其无法将这些语句转变为对应的硬件电路。

---

## 2.8 仿真 P41

### 2.8.1 系统函数 P42

#### 1. $stop

$stop用于对仿真过程进行控制，暂停仿真。

#### 2. $readmemh

$readmemh函数用于读取文件，其作用是从外部文件中读取数据并放入存储器中。

类似的还有$readmemb。

数字中不能包含位宽说明和格式说明，其中readmemb要求每个数字是二进制数，readmemh要求每个数字必须是十六进制数字。

`$readmemh("数据文件名"， 存储对象);`

为了实现对指令存储器的初始化，只需要创建一个数据文件，其内容如上面的rom.data所示，然后在指令存储器rom.v中，增加代码$readmemh("rom.data", rom)即可。

### 2.8.2 Test Bench

```verilog
module <Test Bench名>:
  		<数据类型说明> //激励信号使用reg类型，显示信号使用wire类型
  		<激励向量定义> //always、initial过程快等
  		<待测试模块例化>
endmodule
```

* Test Bench只有模块名，没有端口列表；激励信号必须定义为reg类型，以保持信号值；从待测试模块输出的信号必须定义为wire类型
* 在Test Bench中要调用被测试模块，也就是元件例化
* Test Bench中一般会使用intial、always过程快来定义、描述激励信号

