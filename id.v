`include "defines.v"

module id(
    input wire rst,
    input wire[`InstAddrBus] pc_i,
    input wire[`InstBus] inst_i,

// 读取的Regfile的值
    input wire[`RegBus] reg1_data_i,
    input wire[`RegBus] reg2_data_i,

// 输出到Regfile的信息
    output reg reg1_read_o,
    output reg reg2_read_o,
    output reg[`RegAddrBus] reg1_addr_o,
    output reg[`RegAddrBus] reg2_addr_o,

// 送到EX阶段的信息
    output reg[`AluOpBus] aluop_o,
    output reg[`AluSelBus] alusel_o,
    output reg[`RegBus] reg1_o,
    output reg[`RegBus] reg2_o,
    output reg[`RegAddrBus] wd_o,
    output reg wreg_o
);

// 取得指令的指令码opcode，功能码funct
    wire[6:0] op = inst_i[6:0];
    wire[2:0] funct3 = inst_i[14:12];
    wire[6:0] funct7 = inst_i[31:25];

    // 保存指令执行需要的立即数
    reg[`RegBus] imm;
    // 指示指令是否有效
    reg instvalid;

// 第一段：对指令进行译码
    always @ (*) begin
        if (rst == `RstEnable) begin
            aluop_o <= `EXE_NOP_OP;
            alusel_o <= `EXE_RES_NOP;
            wd_o <= `NOPRegAddr;
            wreg_o <= `WriteDisable;
            instvalid <= `InstValid;
            reg1_read_o <= 1'b0;
            reg2_read_o <= 1'b0;
            reg1_addr_o <= `NOPRegAddr;
            reg2_addr_o <= `NOPRegAddr;
            imm <= 32'h0;
        end else begin
            aluop_o <= `EXE_NOP_OP;
            alusel_o <= `EXE_RES_NOP;
            wd_o <= inst_i[11:7];   //rd的位置
            wreg_o <= `WriteDisable;
            instvalid <= `InstInvalid;
            reg1_read_o <= 1'b0;
            reg2_read_o <= 1'b0;
            reg1_addr_o <= inst_i[19:15];  //默认通过Regfile读端口1读取的寄存器地址
            reg2_addr_o <= inst_i[24:20];  //默认通过Regfile读端口2读取的寄存器地址
            imm <= `ZeroWord;
            
            case (op)
                7'b0010011: begin  //依据op的值判断是否是ori指令
                    case (funct3)
                        3'b110: begin
                            // ori指令需要将结果写入目的寄存器，所以wreg_o为WriteEnable
                            wreg_o <= `WriteEnable;
                            // 运算的子类型是逻辑“或”运算
                            aluop_o <= `EXE_OR_OP;
                            // 运算类型是逻辑预算
                            alusel_o <= `EXE_RES_LOGIC;
                            // 需要通过Regfile的读端口1读取寄存器
                            reg1_read_o = 1'b1;
                            // 不需要通过Regfile的读端口2读取寄存器
                            reg2_read_o = 1'b0;
                            // 指令执行需要的立即数
                            imm <= {{20{inst_i[31]}}, inst_i[31:20]};
                            // 指令执行要写的目的寄存器地址
                            wd_o <= inst_i[11:7];
                            // ori指令是有效指令
                            instvalid <= `InstValid;
                        end
                        default: begin
                            //none
                        end
                    endcase
                end
                default: begin
                    //none
                end
            endcase //case op
        end //if
    end //always

// 第二段：确定进行运算的源操作数1
    always @ (*) begin
        if (rst == `RstEnable) begin
            reg1_o <= `ZeroWord;
        end else if (reg1_read_o == 1'b1) begin
            reg1_o <= reg1_data_i;  //Regfile读端口1的输出值
        end else if (reg1_read_o == 1'b0) begin
            reg1_o <= imm;   //立即数
        end else begin
            reg1_o <= `ZeroWord;
        end
    end

// 第三段：确定进行运算的源操作数2
    always @ (*) begin
        if (rst == `RstEnable) begin
            reg2_o <= `ZeroWord;
        end else if (reg2_read_o == 1'b1) begin
            reg2_o <= reg2_data_i;  //Regfile读端口2的输出值
        end else if (reg2_read_o == 1'b0) begin
            reg2_o <= imm;  
        end else begin
            reg2_o <= `ZeroWord;
        end
    end

endmodule // id