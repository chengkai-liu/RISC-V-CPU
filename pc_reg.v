`include "defines.v"

module pc_reg(
    input wire clk,
    input wire rst,
    output reg[`InstAddrBus] pc,
    output reg ce
);

    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            ce <= `ChipDisable;
        end else begin
            ce <= `ChipEnable;
        end
    end

    always @ (posedge clk) begin
        if (ce == `ChipDisable) begin
            pc <= 32'h00000000; //指令存储器禁用的时候，PC为0
        end else begin
            pc <= pc + 4'h4; //指令存储器使能的时候，PC的值每时钟周期加4
        end
    end

endmodule // pc_reg