`include "defines.v"

module stage_if(
    input wire                      clk,
    input wire                      rst,

    // from ctrl
    input wire[`StallBus]           stall,

    // data input from cpu.v
    input wire[`DataBus]            if_mem_din_i,

    // from id branch
    input wire                      branch_flag_i,
    input wire[`InstAddrBus]        branch_addr_i,

    // from icache
    input wire                      icache_hit_i,
    input wire[`InstBus]            icache_inst_i,

/*---------------------------------------------------------*/

    output reg[`InstAddrBus]        pc_o,
    output reg[`InstBus]            inst_o,

    // cpu output
    output reg[`InstAddrBus]        if_mem_a_o,

    // to ctrl
    output reg                      if_ctrl_req_o,  

    // to icahce
    output reg                      icache_we_o,
    output reg[`InstAddrBus]        icache_waddr_o,
    output reg[`InstBus]            icache_winst_o,

    output reg[`InstAddrBus]        icache_raddr_o
);

reg[3:0]        cnt;
reg[`DataBus]   inst_block1;
reg[`DataBus]   inst_block2;
reg[`DataBus]   inst_block3;

always @ (posedge clk) begin
    if (rst == `RstEnable) begin
        cnt             <= 4'b0000;
        inst_block1     <= `Zero8;
        inst_block2     <= `Zero8;
        inst_block3     <= `Zero8;
        //
        pc_o            <= `ZeroWord;
        inst_o          <= `ZeroWord;
        if_mem_a_o      <= `ZeroWord;
        if_ctrl_req_o   <= `NoStop;
        icache_we_o     <= `WriteDisable;
        icache_waddr_o  <= `ZeroWord;
        icache_winst_o  <= `ZeroWord;
        icache_raddr_o  <= `ZeroWord;
    end else if (stall[1] == `NoStop && branch_flag_i == `Branch) begin
        cnt             <= 4'b0000;
        pc_o            <= branch_addr_i;
        inst_o          <= `ZeroWord;
        if_mem_a_o      <= `ZeroWord;
        if_ctrl_req_o   <= `NoStop;
        icache_raddr_o  <= branch_addr_i;
    end else begin
        case (cnt)
            4'b0000: begin
                icache_we_o         <= `WriteDisable;
                if (stall[1] == `NoStop && stall[2] == `NoStop) begin
                    if_ctrl_req_o           <= `Stop;
                    if_mem_a_o              <= pc_o;
                    icache_raddr_o          <= pc_o;
                    cnt                     <= 4'b0001;
                end
            end
            4'b0001: begin
                if (icache_hit_i == `Hit) begin
                    if (stall[0] == `NoStop) begin
                        inst_o              <= icache_inst_i;
                        if_ctrl_req_o       <= `NoStop;
                        pc_o                <= pc_o + 4;
                        cnt                 <= 4'b0000;
                    end
                end else begin
                    if (stall[0] == `Stop) begin
                        cnt                 <= 4'b1000;
                    end else begin
                        if_mem_a_o          <= pc_o + 4;
                        cnt                 <= 4'b0010;
                    end
                end
            end
            4'b0010: begin
                if_mem_a_o              <= pc_o + 2;
                inst_block1             <= if_mem_din_i;
                cnt                     <= 4'b0011;
            end
            4'b0011: begin
                if (stall[0] == `Stop) begin
                    cnt                 <= 4'b1010;
                end else begin
                    if_mem_a_o          <= pc_o + 3;
                    inst_block2         <= if_mem_din_i;
                    cnt                 <= 4'b0100;
                end
            end
            4'b0100: begin
                if (stall[0] == `Stop) begin
                    cnt                 <= 4'b1100;
                end else begin
                    inst_block3         <= if_mem_din_i;
                    cnt                 <= 4'b0101;
                end
            end
            4'b0101: begin
                inst_o              <= {if_mem_din_i, inst_block3, inst_block2, inst_block1};
                icache_we_o         <= `WriteEnable;
                icache_waddr_o      <= icache_raddr_o;
                icache_winst_o      <= {if_mem_din_i, inst_block3, inst_block2, inst_block1};
                pc_o                <= pc_o + 4;
                cnt                 <= 4'b0000;
            end
/*-----------------------------------------------------------------------------*/
            4'b1000: begin
                if (stall[0] == `NoStop) begin
                    if_mem_a_o      <= pc_o;
                    cnt             <= 4'b1001;
                end
            end
            4'b1001: begin
                if_mem_a_o          <= pc_o + 1;
                cnt                 <= 4'b0010;
            end
            //
            4'b1010: begin
                if (stall[0] == `NoStop) begin
                    if_mem_a_o      <= pc_o + 1;
                    cnt             <= 4'b1011;
                end
            end
            4'b1011: begin
                if_mem_a_o          <= pc_o + 2;
                cnt                 <= 4'b0011;
            end
            //
            4'b1100: begin
                if (stall[0] == `NoStop) begin
                    if_mem_a_o      <= pc_o + 2;
                    cnt             <= 4'b1101;
                end
            end
            4'b1101: begin
                if_mem_a_o          <= pc_o + 3;
                cnt                 <= 4'b0100;
            end
        
            default: begin
            end
        endcase
    end
end

endmodule // if