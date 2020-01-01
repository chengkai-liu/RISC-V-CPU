`include "defines.v"

module ctrl(
    input wire                  rst,
    input wire                  rdy,
    
    input wire                  if_ctrl_req_i,
    input wire                  mem_ctrl_req_i,

    input wire[`InstAddrBus]    if_mem_a_i,   
    input wire[`InstAddrBus]    mem_mem_a_i,   
    input wire                  mem_mem_wr_i,
    input wire[`DataBus]        mem_mem_dout_i,

    output reg[`StallBus]       stall,

    output reg                  mem_wr_o,
    output reg[`InstAddrBus]    mem_a_o,
    output reg[`DataBus]        mem_dout_o
    
);

// 5 wb 4 mem 3 ex 2 id 1 if 0 if_mem

always @ (*) begin
    if (rst == `RstEnable) begin
        stall       <= 6'b000000;
        mem_wr_o    <= `WriteDisable;
        mem_a_o     <= `ZeroWord;
        mem_dout_o  <= `Zero8;
    end else if (rdy == `NotReady) begin
        stall       <= 6'b111111;
        mem_wr_o    <= `WriteDisable;
        mem_a_o     <= `ZeroWord;
        mem_dout_o  <= `Zero8;
    end else if (mem_ctrl_req_i == `Stop) begin
        stall       <= 6'b111111;
        mem_wr_o    <= mem_mem_wr_i;
        mem_a_o     <= mem_mem_a_i;
        mem_dout_o  <= mem_mem_dout_i;
    end else if (if_ctrl_req_i == `Stop) begin
        stall       <= 6'b000010;      
        mem_wr_o    <= `WriteDisable;
        mem_a_o     <= if_mem_a_i;
        mem_dout_o  <= `Zero8;
    end else begin
        stall       <= 6'b000000;
        mem_wr_o    <= `WriteDisable;
        mem_a_o     <= `ZeroWord;
        mem_dout_o  <= `Zero8;
    end
end

endmodule // ctrl