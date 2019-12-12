`include "defines.v"

module pc_reg(
    input wire                  clk,
    input wire                  rst,
    input wire                  rdy,

    // from ctrl
    input wire[`StallBus]       stall,

    // branch from id
    input wire                  branch_flag_i,
    input wire[`RegBus]         branch_addr_i,

    // to if
    output reg[`InstAddrBus]    pc
);

    always @ (posedge clk) begin
        if (rst == `RstEnable)  begin
            pc <= 32'h00000000;
        end else if (branch_flag_i == `Branch) begin
            pc <= branch_addr_i;
        end else if (rdy && stall[0] == `NoStop) begin // todo stall[0]
            pc <= pc + 4'h4;
        end
    end

endmodule // pc_reg