//全局的宏定义
`define RstEnable 1'b1 //复位信号rst有效
`define RstDisable 1'b0 //复位信号rst无效
`define WriteEnable 1'b1 //使能写
`define WriteDisable 1'b0 //禁止写
`define ReadEnable 1'b1 //使能读
`define ReadDisable 1'b0 //禁止读
`define InstValid 1'b1 //指令有效
`define InstInvalid 1'b0 //指令无效
`define True_v 1'b1 //逻辑真
`define False_v 1'b0 //逻辑假
`define ChipEnable 1'b1 //芯片使能
`define ChipDisable 1'b0 //芯片禁止

`define ZeroWord 32'h00000000 //32位的数值0
`define AluOpBus 7:0 //ID阶段的输出aluop_o的宽度
`define AluSelBus 2:0 //ID阶段输出alusel_o的宽度
`define OpcodeBus 6:0
`define Funct3Bus 2:0
`define Funct7BUs 6:0

// opcode 
`define NOP_OP              7'b0000000 // NOP
`define I_OP                7'b0010011 // ADDI SLTI SLTIU XORI ORI ANDI, SLLI SRLI SRAI
`define R_OP                7'b0110011 // ADD SUB SLL SLT SLTU XOR SRL SRA OR AND
`define LUI_OP              7'b0110111 // LUI
`define AUIPC_OP            7'b0010111 // AUIPC
`define JAL_OP              7'b1101111 // JAL
`define JALR_OP             7'b1100111 // JALR
`define BRANCH_OP           7'b1100011 // BEQ BNE BLT BGE BLTU BGEU
`define LOAD_OP             7'b0000011 // LB LH LW LBU LHU
`define STORE_OP            7'b0100011 // SB SH SW

// funct3
`define NOP_FUNCT3          3'b000
`define ADDI_FUNCT3         3'b000
`define SLTI_FUNCT3         3'b010
`define SLTIU_FUNCT3        3'b011
`define XORI_FUNCT3         3'b100
`define ORI_FUNCT3          3'b110
`define ANDI_FUNCT3         3'b111
`define SLLI_FUNCT3         3'b001
`define SRLI_SRAI_FUNCT3    3'b101
`define ADD_SUB_FUNCT3      3'b000
`define SLL_FUNCT3          3'b001
`define SLT_FUNCT3          3'b010
`define SLTU_FUNCT3         3'b011
`define XOR_FUNCT3          3'b100
`define SRL_SRA_FUNCT3      3'b101
`define OR_FUNCT3           3'b110
`define AND_FUNCT3          3'b111
`define BEQ_FUNCT3          3'b000
`define BNE_FUNCT3          3'b001
`define BLT_FUNCT3          3'b100
`define BGE_FUNCT3          3'b101
`define BLTU_FUNCT3         3'b110
`define BGEU_FUNCT3         3'b111
`define LB_FUNCT3           3'b000
`define LH_FUNCT3           3'b001
`define LW_FUNCT3           3'b010
`define LBU_FUNCT3          3'b100
`define LHU_FUNCT3          3'b101
`define SB_FUNCT3           3'b000
`define SH_FUNCT3           3'b001
`define SW_FUNCT3           3'b010

// funct7
`define NOP_FUNCT7          7'b0000000
`define ADD_FUNCT7          7'b0000000
`define SUB_FUNCT7          7'b0100000
`define SRLI_FUNCT7          7'b0000000
`define SRAI_FUNCT7          7'b0100000
`define SRL_FUNCT7          7'b0000000
`define SRA_FUNCT7          7'b0100000

//Bus是线宽度，Num是数量，Width是宽度，Log2是二进制位数

//与指令存储器ROM有关的宏定义
`define InstAddrBus 31:0 //ROM的地址总线宽度
`define InstBus 31:0 //ROM的数据总线宽度
`define InstMemNum 131071 //ROM的实际大小为128KB
`define InstMemNumLog2 17 //ROM实际使用的地址线宽度

//与通用寄存器Regfile有关的宏定义
`define RegAddrBus 4:0 //Regfile模块的地址线宽度
`define RegBus 31:0 //Regfile模块的数据线宽度
`define RegWidth 32 //通用寄存器的宽度
`define DoubleRegWidth 64 //两倍的通用寄存器的宽度
`define DoubleRegBus 63:0 //两倍的通用寄存器的数据线宽度
`define RegNum 32 //通用寄存器的数量
`define RegNumLog2 5 //寻址通用寄存器使用的地址位数
`define NOPRegAddr 5'b00000
