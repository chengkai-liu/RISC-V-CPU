`include "defines.v"

module if_id(
    input wire clk,
    input wire rst,
    //来自IF阶段的信号，其中宏定义InstBus表示指令宽度，为32
    input wire[`InstAddrBus] if_pc,
    input wire[`InstBus] if_inst,
    //对应ID阶段的信号
    output reg[`InstAddrBus] id_pc,
    output reg[`InstBus] id_inst
);

    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            id_pc <= `ZeroWord; //复位的时候pc为0
            id_inst <= `ZeroWord; //复位的时候指令也为0，实际就是空指令
        end else begin
            id_pc <= if_pc; //其余时刻向下传递IF阶段的值
            id_inst <= if_inst;
        end
    end

endmodule // if_id