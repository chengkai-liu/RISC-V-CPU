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

    output reg[`InstAddrBus]        pc_o,   // pc + 4
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

reg[3:0]                    cnt;
reg[`DataBus]               inst_block1;
reg[`DataBus]               inst_block2;
reg[`DataBus]               inst_block3;

integer i;
always @ (posedge clk) begin
    if (rst == `RstEnable) begin
        cnt             <= `If0;
        inst_block1     <= `Zero8;
        inst_block2     <= `Zero8;
        inst_block3     <= `Zero8;
        //----------------------------
        pc_o            <= `ZeroWord;
        inst_o          <= `ZeroWord;
        if_mem_a_o      <= `ZeroWord;
        if_ctrl_req_o   <= `NoStop;
        icache_we_o     <= `WriteDisable;
        icache_waddr_o  <= `ZeroWord;
        icache_winst_o  <= `ZeroWord;
        icache_raddr_o  <= `ZeroWord;
    end else if (branch_flag_i == `Branch && stall[0] == `NoStop) begin // fixme unsure but accounts
        cnt             <= `If0;
        pc_o            <= branch_addr_i;
        inst_o          <= `ZeroWord;
        if_mem_a_o      <= `ZeroWord;
        if_ctrl_req_o   <= `NoStop;
        icache_raddr_o  <= branch_addr_i;
    end else begin
        case (cnt)
            `If0: begin
                icache_we_o         <= `WriteDisable;
                if (stall[1] == `NoStop && stall[2] == `NoStop) begin
                    if_ctrl_req_o           <= `Stop;
                    if_mem_a_o              <= pc_o;
                    icache_raddr_o          <= pc_o;
                    cnt                     <= `If1;
                end
            end
            `If1: begin
                if (icache_hit_i == `Hit) begin
                    if (stall[0] == `NoStop) begin
                        inst_o              <= icache_inst_i;
                        if_ctrl_req_o       <= `NoStop;
                        pc_o                <= pc_o + 4;
                        cnt                 <= `If0; // fetched
                    end
                end else begin
                    if (stall[0] == `Stop) begin
                        cnt                 <= `ReIf00;
                    end else begin
                        if_mem_a_o          <= pc_o + 1;
                        cnt                 <= `If2;
                    end
                end
            end
            `If2: begin
                if_mem_a_o              <= pc_o + 2;
                inst_block1             <= if_mem_din_i;
                cnt                     <= `If3;
            end
            `If3: begin
                if (stall[0] == `Stop) begin
                    cnt                 <= `ReIf11;
                end else begin
                    if_mem_a_o          <= pc_o + 3;
                    inst_block2         <= if_mem_din_i;
                    cnt                 <= `If4;
                end
            end
            `If4: begin
                if (stall[0] == `Stop) begin
                    cnt                 <= `ReIf22;
                end else begin
                    inst_block3         <= if_mem_din_i;
                    cnt                 <= `If5;
                end
            end
            `If5: begin
                inst_o              <= {if_mem_din_i, inst_block3, inst_block2, inst_block1};
                icache_we_o         <= `WriteEnable;
                icache_waddr_o      <= icache_raddr_o;
                icache_winst_o      <= {if_mem_din_i, inst_block3, inst_block2, inst_block1};
                if_ctrl_req_o       <= `NoStop;
                pc_o                <= pc_o + 4;
                cnt                 <= `If0;
            end
/*-----------------------------------------------------------------------------*/
            `ReIf00: begin
                if (stall[0] == `NoStop) begin
                    if_mem_a_o      <= pc_o;
                    cnt             <= `ReIf01;
                end
            end
            `ReIf01: begin
                if_mem_a_o          <= pc_o + 1;
                cnt                 <= `If2;
            end
            //-----------------------------------
            `ReIf11: begin
                if (stall[0] == `NoStop) begin
                    if_mem_a_o      <= pc_o + 1;
                    cnt             <= `ReIf12;
                end
            end
            `ReIf12: begin
                if_mem_a_o          <= pc_o + 2;
                cnt                 <= `If3;
            end
            //-----------------------------------
            `ReIf22: begin
                if (stall[0] == `NoStop) begin
                    if_mem_a_o      <= pc_o + 2;
                    cnt             <= `ReIf23;
                end
            end
            `ReIf23: begin
                if_mem_a_o          <= pc_o + 3;
                cnt                 <= `If4;
            end
        
            default: begin
            end
        endcase
    end
end

endmodule // if