`include "defines.v"

module pc_reg(
    input wire clk,
    input wire rst,

    input wire      branch_flag_i,
    input wire      branch_addr_i,

    output reg[`InstAddrBus] pc
);

    always @ (posedge clk) begin
        if (rst == `RstEnable)  begin
            pc <= 32'h00000000;
        end else if (branch_flag_i == 1'b1) begin
            pc <= branch_addr_i;
        end else begin
            pc <= pc + 4'h4;
        end
    end

endmodule // pc_reg