`include "defines.v"

module pc_reg(
    input wire clk,
    input wire rst,

    output reg[`InstAddrBus] pc
);

    always @ (posedge clk) begin
        if (rst == `RstEnable)  begin
            pc <= 32'h00000000;
        end else begin
            pc <= pc + 4'h4;
        end
    end

endmodule // pc_reg