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
    input wire[`RegBus]         id_jump_link_addr,
    input wire[`InstAddrBus]    id_ls_offset,
       
    // to ex
    output reg[`AluOpBus]       ex_aluop,
    output reg[`AluSelBus]      ex_alusel,
    output reg[`RegBus]         ex_reg1,
    output reg[`RegBus]         ex_reg2,
    output reg                  ex_wreg,
    output reg[`RegAddrBus]     ex_wd,
    output reg[`RegBus]         ex_jump_link_addr,
    output reg[`InstAddrBus]    ex_ls_offset
);

always @ (posedge clk) begin
    if (rst == `RstEnable) begin
        ex_aluop            <= `EXE_NOP_OP;
        ex_alusel           <= `EXE_RES_NOP;
        ex_reg1             <= `ZeroWord;
        ex_reg2             <= `ZeroWord;
        ex_wreg             <= `WriteDisable;
        ex_wd               <= `NOPRegAddr;
        ex_jump_link_addr   <= `ZeroWord;
        ex_ls_offset        <= `ZeroWord;
    end else if (stall[2] == `Stop && stall[3] == `NoStop) begin
        ex_aluop            <= `EXE_NOP_OP;
        ex_alusel           <= `EXE_RES_NOP;
        ex_reg1             <= `ZeroWord;
        ex_reg2             <= `ZeroWord;
        ex_wreg             <= `WriteDisable;
        ex_wd               <= `NOPRegAddr;
        ex_jump_link_addr   <= `ZeroWord;
        ex_ls_offset        <= `ZeroWord;
    end else if (stall[2] == `NoStop) begin
        ex_aluop            <= id_aluop;
        ex_alusel           <= id_alusel;
        ex_reg1             <= id_reg1;
        ex_reg2             <= id_reg2;
        ex_wreg             <= id_wreg;
        ex_wd               <= id_wd;
        ex_jump_link_addr   <= id_jump_link_addr;
        ex_ls_offset        <= id_ls_offset;
    end
end

endmodule // id_ex