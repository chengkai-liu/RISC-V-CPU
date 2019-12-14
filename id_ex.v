`include "defines.v"

module id_ex(
    input wire          clk,
    input wire          rst,

    // from ctrl
    input wire[`StallBus]       stall,

    // from id
    input wire[`AluOpBus]       id_aluop,
    input wire[`AluSelBus]      id_alusel,
    input wire[`RegBus]         id_reg1,
    input wire[`RegBus]         id_reg2,
    input wire                  id_wreg,
    input wire[`RegAddrBus]     id_wd,
    input wire[`RegBus]         id_jb_link_addr,
       
    // to ex
    output reg[`AluOpBus]       ex_aluop,
    output reg[`AluSelBus]      ex_alusel,
    output reg[`RegBus]         ex_reg1,
    output reg[`RegBus]         ex_reg2,
    output reg                  ex_wreg,
    output reg[`RegAddrBus]     ex_wd,
    output reg[`RegBus]         ex_jb_link_addr
);

always @ (posedge clk) begin
    if (rst == `RstEnable) begin
        ex_aluop            <= `EXE_NOP_OP;
        ex_alusel           <= `EXE_RES_NOP;
        ex_reg1             <= `ZeroWord;
        ex_reg2             <= `ZeroWord;
        ex_wreg             <= `WriteDisable;
        ex_wd               <= `NOPRegAddr;
        ex_jb_link_addr     <= `ZeroWord;
    end else if (stall[2] == `Stop && stall[3] == `NoStop) begin
        ex_aluop            <= `EXE_NOP_OP;
        ex_alusel           <= `EXE_RES_NOP;
        ex_reg1             <= `ZeroWord;
        ex_reg2             <= `ZeroWord;
        ex_wreg             <= `WriteDisable;
        ex_wd               <= `NOPRegAddr;
        ex_jb_link_addr     <= `ZeroWord;
    end else if (stall[2] == `NoStop) begin
        ex_aluop            <= id_aluop;
        ex_alusel           <= id_alusel;
        ex_reg1             <= id_reg1;
        ex_reg2             <= id_reg2;
        ex_wreg             <= id_wreg;
        ex_wd               <= id_wd;
        ex_jb_link_addr     <= id_jb_link_addr;
    end
end

endmodule // id_ex