`include "defines.v"

module mem(
    input wire                          clk,
    input wire                          rst,
    
    input wire[`AluOpBus]               aluop_i,
    input wire[`AluSelBus]              alusel_i,

    // from ex
    input wire[`RegAddrBus]             wd_i,
    input wire                          wreg_i,
    input wire[`RegBus]                 wdata_i,

    input wire[`DataBus]                mem_din_i,


    output reg[`RegAddrBus]             wd_o,
    output reg                          wreg_o,
    output reg[`RegBus]                 wdata_o
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