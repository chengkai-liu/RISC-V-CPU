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

    input wire[`AluSelBus]          alusel_i,

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

    // to icache
    output reg                      icache_we_o,
    output reg[`InstAddrBus]        icache_waddr_o,
    output reg[`InstBus]            icache_winst_o,

    output reg[`InstAddrBus]        icache_raddr_o
);

reg[3:0]                    cnt;
reg[`DataBus]               inst_block1;
reg[`DataBus]               inst_block2;
reg[`DataBus]               inst_block3;

reg[1:0]                    bht[`BhtNum - 1:0];        // 2 bit Branch history table, taken/not taken

reg[`InstAddrBus]           pc;

integer i;
always @ (posedge clk) begin
    if (rst == `RstEnable) begin
        cnt             <= `If0;
        inst_block1     <= `Zero8;
        inst_block2     <= `Zero8;
        inst_block3     <= `Zero8;
        //----------------------------
        pc              <= `ZeroWord;
        pc_o            <= `ZeroWord;
        inst_o          <= `ZeroWord;
        if_mem_a_o      <= `ZeroWord;
        if_ctrl_req_o   <= `NoStop;
        icache_we_o     <= `WriteDisable;
        icache_waddr_o  <= `ZeroWord;
        icache_winst_o  <= `ZeroWord;
        icache_raddr_o  <= `ZeroWord;
        //----------------------------
        for (i = 0; i < `BhtNum; i = i + 1) begin
            bht[i]      <= 2'b01;
        end
        //----------------------------
    end else if (alusel_i == `EXE_RES_JB && stall[0] == `NoStop) begin
        // bht update
        if (branch_flag_i == `Branch && bht[(pc_o - 4) % `BhtNum] != 2'b11) begin
            bht[(pc_o - 4) % `BhtNum]       <= bht[(pc_o - 4) % `BhtNum] + 1;
        end else if (bht[(pc_o - 4) % `BhtNum] != 2'b00) begin
            bht[(pc_o - 4) % `BhtNum]       <= bht[(pc_o - 4) % `BhtNum] - 1;
        end
        // check prediction
        if (branch_addr_i != pc) begin
            cnt                 <= `If0;
            pc                  <= branch_addr_i;
            inst_o              <= `ZeroWord;
            if_mem_a_o          <= `ZeroWord;
            if_ctrl_req_o       <= `NoStop;
            icache_raddr_o      <= branch_addr_i;
        end
    end else begin
        case (cnt)
            `If0: begin
                icache_we_o         <= `WriteDisable;
                if (stall[1] == `NoStop && stall[2] == `NoStop) begin
                    if_ctrl_req_o           <= `Stop;
                    if_mem_a_o              <= pc;
                    icache_raddr_o          <= pc;
                    cnt                     <= `If1;
                end
            end
            `If1: begin
                if (icache_hit_i == `Hit) begin
                    if (stall[0] == `NoStop) begin
                        inst_o              <= icache_inst_i;
                        if_ctrl_req_o       <= `NoStop;
                        pc_o                <= pc + 4;
                        cnt                 <= `If0; // fetched
                        // branch prediction
                        if (icache_inst_i[6]) begin
                            if (bht[pc % `BhtNum] == 2'b10 || bht[pc % `BhtNum] == 2'b11) begin
                                pc        <= pc + {{20{icache_inst_i[31]}}, icache_inst_i[7], icache_inst_i[30:25], icache_inst_i[11:8], 1'b0};
                            end else begin
                                pc        <= pc + 4;
                            end
                        end else begin
                                pc        <= pc + 4;
                        end
                    end
                end else begin
                    if (stall[0] == `Stop) begin
                        cnt                 <= `ReIf00;
                    end else begin
                        if_mem_a_o          <= pc + 1;
                        cnt                 <= `If2;
                    end
                end
            end
            `If2: begin
                if_mem_a_o              <= pc + 2;
                inst_block1             <= if_mem_din_i;
                cnt                     <= `If3;
            end
            `If3: begin
                if (stall[0] == `Stop) begin
                    cnt                 <= `ReIf11;
                end else begin
                    if_mem_a_o          <= pc + 3;
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
                pc_o                <= pc + 4;
                // pc                  <= pc + 4;
                cnt                 <= `If0;
                // branch prediction
                if (inst_block1[6]) begin
                    if (bht[pc % `BhtNum] == 2'b10 || bht[pc % `BhtNum] == 2'b11) begin
                        pc        <= pc + {{20{if_mem_din_i[7]}}, inst_block1[7], if_mem_din_i[6:1], inst_block2[3:0], 1'b0};
                    end else begin
                        pc        <= pc + 4;
                    end
                end else begin
                        pc        <= pc + 4;
                end
            end
/*-----------------------------------------------------------------------------*/
            `ReIf00: begin
                if (stall[0] == `NoStop) begin
                    if_mem_a_o      <= pc;
                    cnt             <= `ReIf01;
                end
            end
            `ReIf01: begin
                if_mem_a_o          <= pc + 1;
                cnt                 <= `If2;
            end
            //-----------------------------------
            `ReIf11: begin
                if (stall[0] == `NoStop) begin
                    if_mem_a_o      <= pc + 1;
                    cnt             <= `ReIf12;
                end
            end
            `ReIf12: begin
                if_mem_a_o          <= pc + 2;
                cnt                 <= `If3;
            end
            //-----------------------------------
            `ReIf22: begin
                if (stall[0] == `NoStop) begin
                    if_mem_a_o      <= pc + 2;
                    cnt             <= `ReIf23;
                end
            end
            `ReIf23: begin
                if_mem_a_o          <= pc + 3;
                cnt                 <= `If4;
            end
        
            default: begin
            end
        endcase
    end
end

endmodule // if