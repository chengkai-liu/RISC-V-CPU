`include "defines.v"

module ex_mem(
    input wire  clk,
    input wire  rst,

    // from ctrl
    input wire[`StallBus]           stall,

    // from ex
    input wire[`RegAddrBus]         ex_wd,
    input wire                      ex_wreg,
    input wire[`RegBus]             ex_wdata,

    input wire[`AluOpBus]           aluop_i,
    input wire[`AluSelBus]          alusel_i,

    input wire[`InstAddrBus]        ex_ma_addr,

    // to mem
    output reg[`RegAddrBus]         mem_wd,
    output reg                      mem_wreg,
    output reg[`RegBus]             mem_wdata,

    output reg[`AluOpBus]           aluop_o,
    output reg[`AluSelBus]          alusel_o,

    output reg[`InstAddrBus]        mem_ma_addr
);

always @ (posedge clk) begin
    if (rst == `RstEnable) begin
        mem_wd              <= `NOPRegAddr;
        mem_wreg            <= `WriteDisable;
        mem_wdata           <= `ZeroWord;
        aluop_o             <= `EXE_NOP_OP;
        alusel_o            <= `EXE_RES_NOP;
        mem_ma_addr       <= `ZeroWord;
    end else if (stall[3] == `Stop && stall[4] == `NoStop) begin
        mem_wd              <= `NOPRegAddr;
        mem_wreg            <= `WriteDisable;
        mem_wdata           <= `ZeroWord;    
        aluop_o             <= `EXE_NOP_OP;
        alusel_o            <= `EXE_RES_NOP;
        mem_ma_addr         <= `ZeroWord;
    end else if (stall[3] == `NoStop) begin
        mem_wd              <= ex_wd;
        mem_wreg            <= ex_wreg;
        mem_wdata           <= ex_wdata;
        aluop_o             <= aluop_i;
        alusel_o            <= alusel_i;
        mem_ma_addr         <= ex_ma_addr;
    end
end

endmodule // ex_mem