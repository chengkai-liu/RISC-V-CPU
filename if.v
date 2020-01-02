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

/*---------------------------------------------------------*/

    output reg[`InstAddrBus]        pc_o,   // pc + 4
    output reg[`InstBus]            inst_o,

    // cpu output
    output reg[`InstAddrBus]        if_mem_a_o,

    // to ctrl
    output reg                      if_ctrl_req_o,
    output reg                      branch_ctrl_req_o
);

reg[`InstAddrBus]           pc;

reg[3:0]                    cnt;
reg[`DataBus]               inst_block1;
reg[`DataBus]               inst_block2;
reg[`DataBus]               inst_block3;

// icache
reg                         valid_bit[`BlockNum - 1:0];
reg[`TagBus]                cache_tag[`BlockNum - 1:0];    
reg[`InstBus]               cache_data[`BlockNum - 1:0];

//
wire[`InstAddrBus]          addr;
assign                      addr = pc;
//
wire[`IndexBus]             index;
wire[`TagBus]               tag;
//
assign index               = addr[`BlockNumLog2 - 1:0];
assign tag                 = addr[17:`BlockNumLog2];

wire                        r_valid;
wire[`TagBus]               r_cache_tag;
wire[`InstBus]              r_cache_inst;

assign r_valid              = valid_bit[index];
assign r_cache_tag          = cache_tag[index];
assign r_cache_inst         = cache_data[index];

integer i;
always @ (posedge clk) begin
    if (rst == `RstEnable) begin
        cnt                 <= `If0;
        inst_block1         <= `Zero8;
        inst_block2         <= `Zero8;
        inst_block3         <= `Zero8;
        //----------------------------
        pc                  <= `ZeroWord;
        pc_o                <= `ZeroWord;
        inst_o              <= `ZeroWord;
        if_mem_a_o          <= `ZeroWord;
        if_ctrl_req_o       <= `NoStop;
        branch_ctrl_req_o   <= `NoStop;
        //----------------------------
        for (i = 0; i < `BlockNum; i = i + 1) begin
            valid_bit[i]    <= `Invalid;
        end
    end else if (branch_flag_i == `Branch && stall[0] == `NoStop) begin
        cnt                 <= `If0;
        pc                  <= branch_addr_i;
        pc_o                <= branch_addr_i;
        inst_o              <= `ZeroWord;
        if_mem_a_o          <= `ZeroWord;
        if_ctrl_req_o       <= `NoStop;
        branch_ctrl_req_o   <= `Stop;
    end else begin
        branch_ctrl_req_o   <= `NoStop;
        case (cnt)
            `If0: begin
                if (stall[0] == `NoStop) begin
                    if ((tag == r_cache_tag) && r_valid == `Valid) begin
                        inst_o                  <= r_cache_inst;
                        if_ctrl_req_o           <= `NoStop;
                        pc                      <= pc + 4;
                        pc_o                    <= pc + 4;
                        cnt                     <= `If0;    // cache hit
                    end else begin
                        if_mem_a_o              <= pc;
                        if_ctrl_req_o           <= `Stop;
                        cnt                     <= `If1;
                    end
                end
            end
            `If1: begin
                if (stall[0] == `Stop) begin
                    cnt                 <= `ReIf00;
                end else begin
                    if_mem_a_o          <= pc + 1;
                    cnt                 <= `If2;
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
                inst_o                  <= {if_mem_din_i, inst_block3, inst_block2, inst_block1};
                // icache
                valid_bit[index]        <= `Valid;
                cache_tag[index]        <= addr[17:`BlockNumLog2];
                cache_data[index]       <= {if_mem_din_i, inst_block3, inst_block2, inst_block1};
                //
                if_ctrl_req_o           <= `NoStop;
                pc                      <= pc + 4;
                pc_o                    <= pc + 4;
                cnt                     <= `If0;
                
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