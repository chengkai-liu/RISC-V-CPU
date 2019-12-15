`include "defines.v"

module stage_mem(
    input wire                          clk,
    input wire                          rst,
    
    input wire[`AluOpBus]               aluop_i,
    input wire[`AluSelBus]              alusel_i,

    // from ex
    input wire[`RegAddrBus]             wd_i,
    input wire                          wreg_i,
    input wire[`RegBus]                 wdata_i,
    // cpu.v
    input wire[`DataBus]                mem_mem_din_i,

    // to wb    
    output reg[`RegAddrBus]             wd_o,
    output reg                          wreg_o,
    output reg[`RegBus]                 wdata_o,

    // to ctrl
    output reg                          mem_ctrl_req_o,
    // cpu.v
    output reg                          mem_mem_wr_o,
    output reg[`InstAddrBus]            mem_mem_a_o,
    output reg[`DataBus]                mem_mem_dout_o
);

always @ (*) begin
    if (rst == `RstEnable) begin
        wd_o        <= `NOPRegAddr;
        wreg_o      <= `WriteDisable;
        wdata_o     <= `ZeroWord;
    end else begin
        wd_o        <= wd_i;
        wreg_o      <= wreg_i;
        wdata_o     <= wdata_i;
    end
end

endmodule // mem