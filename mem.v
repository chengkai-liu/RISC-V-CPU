`include "defines.v"

module stage_mem(
    input wire                          clk,
    input wire                          rst,
    
    input wire[`AluOpBus]               aluop_i,
    input wire[`AluSelBus]              alusel_i,

    // from ex
    input wire[`RegAddrBus]             wd_i,
    input wire                          wreg_i,
    input wire[`RegBus]                 wdata_i,

    input wire[`InstAddrBus]            ma_addr_i,
    // cpu.v
    input wire[`DataBus]                mem_mem_din_i,

    // to wb    
    output reg[`RegAddrBus]             wd_o,
    output reg                          wreg_o,
    output reg[`RegBus]                 wdata_o,

    // to ctrl
    output reg                          mem_ctrl_req_o,
    // cpu.v
    output reg                          mem_mem_wr_o,
    output reg[`InstAddrBus]            mem_mem_a_o,
    output reg[`DataBus]                mem_mem_dout_o
);

reg[2:0]                cnt;
reg[`DataBus]           data_block1;
reg[`DataBus]           data_block2;
reg[`DataBus]           data_block3;

reg                     mem_access;
reg[`RegBus]            load_data;

// dcache
reg                     valid_bit[`BlockNum - 1:0];
reg[`TagBus]            cache_tag[`BlockNum - 1:0];
reg[`InstBus]           cache_data[`BlockNum - 1:0];
//
wire[`InstAddrBus]      addr;
assign                  addr = ma_addr_i;
//
wire[`IndexBus]         index;
wire[`TagBus]           tag;
//
assign index            = addr[`BlockNumLog2 - 1:0];
assign tag              = addr[17:`BlockNumLog2];
//
wire                    r_valid;
wire[`TagBus]           r_cache_tag;
wire[`InstBus]          r_cache_data;
//
assign r_valid          = valid_bit[index];
assign r_cache_tag      = cache_tag[index];
assign r_cache_data     = cache_data[index];

reg                     hit;

always @ (*) begin
    if (rst == `RstEnable) begin
        mem_ctrl_req_o      <= `NoStop;
    end else if (mem_access == `False_v) begin
        mem_ctrl_req_o      <= `False_v;
    end else if (mem_access == `True_v) begin
        mem_ctrl_req_o      <= ((alusel_i == `EXE_RES_LOAD) || (alusel_i == `EXE_RES_STORE));
    end
end

integer i;
always @ (posedge clk) begin
    if (rst == `RstEnable) begin
        mem_mem_wr_o        <= `WriteDisable;
        mem_mem_a_o         <= `ZeroWord;
        mem_mem_dout_o      <= `Zero8;
        cnt                 <= `Mem0;
        data_block1         <= `Zero8;
        data_block2         <= `Zero8;
        data_block3         <= `Zero8;
        mem_access          <= `True_v;
        load_data           <= `ZeroWord;
        //-----------------------------------
        for (i = 0; i < `BlockNum; i = i + 1) begin
            valid_bit[i]    <= `Invalid;
        end
        hit <= 1'b0;
    end else if (mem_ctrl_req_o == `NoStop) begin
        mem_access          <= `True_v;
    end else if (mem_ctrl_req_o == `Stop) begin
        hit <= 1'b0;
        case (cnt)
            `Mem0: begin
                mem_access      <= `True_v;
                case (alusel_i)
                    `EXE_RES_LOAD: begin
                        if ((tag == r_cache_tag) && r_valid == `Valid) begin
                            hit <= 1'b1;
                            case (aluop_i)
                                `EXE_LB_OP: begin
                                    load_data       <= {{24{r_cache_data[7]}}, r_cache_data[7:0]};
                                    mem_mem_a_o     <= `ZeroWord;
                                    mem_access      <= `False_v;
                                    cnt             <= `Mem0;
                                end
                                `EXE_LH_OP: begin
                                    load_data       <= {{16{r_cache_data[15]}}, r_cache_data[15:0]};
                                    mem_mem_a_o     <= `ZeroWord;
                                    mem_access      <= `False_v;
                                    cnt             <= `Mem0;
                                end
                                `EXE_LHU_OP: begin
                                    load_data       <= {24'b0, r_cache_data[15:0]};
                                    mem_mem_a_o     <= `ZeroWord;
                                    mem_access      <= `False_v;
                                    cnt             <= `Mem0;
                                end
                                `EXE_LW_OP: begin
                                    load_data       <= r_cache_data;
                                    mem_mem_a_o     <= `ZeroWord;
                                    mem_access      <= `False_v;
                                    cnt             <= `Mem0;
                                end
                                default: begin
                                end
                            endcase
                        end else begin
                            mem_mem_wr_o        <= `WriteDisable;
                            mem_mem_a_o         <= ma_addr_i;
                            cnt                 <= `Mem1;
                        end
                    end
                    `EXE_RES_STORE: begin
                        mem_mem_wr_o        <= `WriteEnable;
                        mem_mem_a_o         <= ma_addr_i;
                        mem_mem_dout_o      <= wdata_i[7:0];
                        cnt                 <= `Mem1;
                    end
                    default: begin
                    end
                endcase
            end
            `Mem1: begin
                case (aluop_i)
                        `EXE_LB_OP, `EXE_LBU_OP: begin
                            cnt                 <= `Mem2;
                        end
                        `EXE_LH_OP, `EXE_LHU_OP, `EXE_LW_OP: begin
                            mem_mem_a_o         <= ma_addr_i + 1;
                            cnt                 <= `Mem2;
                        end
                        `EXE_SB_OP: begin
                            mem_mem_wr_o        <= `WriteDisable;
                            mem_mem_a_o         <= `ZeroWord;
                            mem_access          <= `False_v;
                            cnt                 <= `Mem0; // SB--2CC
                        end
                        `EXE_SH_OP, `EXE_SW_OP: begin
                            mem_mem_a_o         <= ma_addr_i + 1;
                            mem_mem_dout_o      <= wdata_i[15:8];
                            cnt                 <= `Mem2;
                        end
                        default: begin
                        end 
                endcase
            end
            `Mem2: begin
                case (aluop_i)
                    `EXE_LB_OP: begin
                        load_data           <= {{24{mem_mem_din_i[7]}}, mem_mem_din_i};
                        mem_mem_a_o         <= `ZeroWord;
                        mem_access          <= `False_v;
                        cnt                 <= `Mem0; // LB--3CC
                    end
                    `EXE_LBU_OP: begin
                        load_data           <= {24'b0, mem_mem_din_i};
                        mem_mem_a_o         <= `ZeroWord;
                        mem_access          <= `False_v;
                        cnt                 <= `Mem0; // LBU--3CC
                    end
                    `EXE_LH_OP, `EXE_LHU_OP: begin
                        data_block1         <= mem_mem_din_i;
                        cnt                 <= `Mem3;
                    end
                    `EXE_LW_OP: begin
                        data_block1         <= mem_mem_din_i;
                        mem_mem_a_o         <= ma_addr_i + 2;
                        cnt                 <= `Mem3;
                    end
                    `EXE_SH_OP: begin
                        mem_mem_wr_o        <= `WriteDisable;
                        mem_mem_a_o         <= `ZeroWord;
                        mem_access          <= `False_v;
                        cnt                 <= `Mem0; // SH--3CC
                    end
                    `EXE_SW_OP: begin
                        mem_mem_a_o         <= ma_addr_i + 2;
                        mem_mem_dout_o      <= wdata_i[23:16];
                        cnt                 <= `Mem3;
                    end
                    default: begin
                    end
                endcase
            end
            `Mem3: begin
                case (aluop_i)
                    `EXE_LH_OP: begin
                        load_data           <= {{16{mem_mem_din_i[7]}}, mem_mem_din_i, data_block1};
                        mem_mem_a_o         <= `ZeroWord;
                        mem_access          <= `False_v;
                        cnt                 <= `Mem0; // LH--4CC
                    end
                    `EXE_LHU_OP: begin
                        load_data           <= {16'b0, mem_mem_din_i, data_block1};
                        mem_mem_a_o         <= `ZeroWord;
                        mem_access          <= `False_v;
                        cnt                 <= `Mem0; // LHU--4CC
                    end
                    `EXE_LW_OP: begin
                        data_block2         <= mem_mem_din_i;
                        mem_mem_a_o         <= ma_addr_i + 3;
                        cnt                 <= `Mem4;
                    end
                    `EXE_SW_OP: begin
                        mem_mem_a_o         <= ma_addr_i + 3;
                        mem_mem_dout_o      <= wdata_i[31:24];
                        cnt                 <= `Mem4;
                    end
                    default: begin
                    end
                endcase
            end
            `Mem4: begin
                case (aluop_i)
                    `EXE_LW_OP: begin
                        data_block3         <= mem_mem_din_i;
                        cnt                 <= `Mem5;
                    end
                    `EXE_SW_OP: begin
                        mem_mem_wr_o        <= `WriteDisable;
                        mem_mem_a_o         <= `ZeroWord;
                        mem_access          <= `False_v;
                        cnt                 <= `Mem0; // SW--5CC
                        // cache
                        valid_bit[index]    <= `Valid;
                        cache_tag[index]    <= addr[17:`BlockNumLog2];
                        cache_data[index]   <= wdata_i;
                    end
                    default: begin
                    end
                endcase
            end
            `Mem5: begin
                case (aluop_i)
                    `EXE_LW_OP: begin
                        load_data           <= {mem_mem_din_i, data_block3, data_block2, data_block1};
                        mem_mem_a_o         <= `ZeroWord;
                        mem_access          <= `False_v;
                        cnt                 <= `Mem0; // LW--6CC
                        // cache
                        valid_bit[index]    <= `Valid;
                        cache_tag[index]    <= addr[17:`BlockNumLog2];
                        cache_data[index]   <= {mem_mem_din_i, data_block3, data_block2, data_block1};
                    end
                endcase
            end
            default: begin
            end
        endcase
    end
end


always @ (*) begin
    if (rst == `RstEnable) begin
        wd_o        <= `NOPRegAddr;
        wreg_o      <= `WriteDisable;
        wdata_o     <= `ZeroWord;
    end else begin
        wd_o        <= wd_i;
        wreg_o      <= wreg_i;
        case (alusel_i) 
            `EXE_RES_LOAD: begin
                wdata_o     <= load_data;
            end
            default: begin
                wdata_o     <= wdata_i;
            end
        endcase
    end
end

endmodule // mem