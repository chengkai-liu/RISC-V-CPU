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

    // from dcache
    input wire                          dcache_hit_i,
    input wire[`RegBus]                 dcache_data_i,

    // to wb    
    output reg[`RegAddrBus]             wd_o,
    output reg                          wreg_o,
    output reg[`RegBus]                 wdata_o,

    // to ctrl
    output reg                          mem_ctrl_req_o,
    // cpu.v
    output reg                          mem_mem_wr_o,
    output reg[`InstAddrBus]            mem_mem_a_o,
    output reg[`DataBus]                mem_mem_dout_o,

    // to dcache
    output reg                          dcache_we_o,
    output reg[`InstAddrBus]            dcache_waddr_o,
    output reg[`RegBus]                 dcache_wdata_o,

    output reg[`InstAddrBus]            dcache_raddr_o
);

reg[2:0]            cnt;
reg[`DataBus]       data_block1;
reg[`DataBus]       data_block2;
reg[`DataBus]       data_block3;

reg                 mem_access;
reg[`RegBus]        load_data;


always @ (*) begin
    if (rst == `RstEnable) begin
        mem_ctrl_req_o      <= `NoStop;
    end else if (mem_access == `False_v) begin
        mem_ctrl_req_o      <= `NoStop;
    end else if (mem_access == `True_v) begin
        mem_ctrl_req_o      <= ((alusel_i == `EXE_RES_LOAD) || (alusel_i == `EXE_RES_STORE));
    end
end

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
        dcache_we_o         <= `WriteDisable;
        dcache_waddr_o      <= `ZeroWord;
        dcache_wdata_o      <= `ZeroWord;
        dcache_raddr_o      <= `ZeroWord;
    end else if (mem_ctrl_req_o == `NoStop) begin
        mem_access          <= `True_v;
    end else if (mem_ctrl_req_o == `Stop) begin
        // dcache
        dcache_we_o         <= `WriteDisable;
        dcache_waddr_o      <= `ZeroWord;
        dcache_wdata_o      <= `ZeroWord;
        dcache_raddr_o      <= `ZeroWord;
        case (cnt)
            `Mem0: begin
                mem_access      <= `True_v;
                case (alusel_i)
                    `EXE_RES_LOAD: begin
                        mem_mem_wr_o        <= `WriteDisable;
                        mem_mem_a_o         <= ma_addr_i;
                        cnt                 <= `Mem1;
                        // dcache
                        dcache_raddr_o      <= ma_addr_i;
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
                if (dcache_hit_i == `Hit) begin
                    case (aluop_i)
                        `EXE_LB_OP: begin
                            load_data       <= {{24{dcache_data_i[7]}}, dcache_data_i[7:0]};
                            mem_mem_a_o     <= `ZeroWord;
                            mem_access      <= `False_v;
                            cnt             <= `Mem0;
                        end
                        `EXE_LBU_OP: begin
                            load_data       <= {24'b0, dcache_data_i[7:0]};
                            mem_mem_a_o     <= `ZeroWord;
                            mem_access      <= `False_v;
                            cnt             <= `Mem0;
                        end
                        `EXE_LH_OP: begin
                            load_data       <= {{16{dcache_data_i[15]}}, dcache_data_i[15:0]};
                            mem_mem_a_o     <= `ZeroWord;
                            mem_access      <= `False_v;
                            cnt             <= `Mem0;
                        end
                        `EXE_LHU_OP: begin
                            load_data       <= {24'b0, dcache_data_i[15:0]};
                            mem_mem_a_o     <= `ZeroWord;
                            mem_access      <= `False_v;
                            cnt             <= `Mem0;
                        end
                        `EXE_LW_OP: begin
                            load_data       <= dcache_data_i;
                            mem_mem_a_o     <= `ZeroWord;
                            mem_access      <= `False_v;
                            cnt             <= `Mem0;
                        end
                        default: begin
                        end
                    endcase // cache hit -- 2CC
                end else begin
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
                            // cache
                            dcache_we_o         <= `WriteEnable;
                            dcache_waddr_o      <= ma_addr_i;
                            dcache_wdata_o      <= wdata_i;
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
                        // cache
                        dcache_we_o         <= `WriteEnable;
                        dcache_waddr_o      <= ma_addr_i;
                        dcache_wdata_o      <= wdata_i;
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
                        dcache_we_o         <= `WriteEnable;
                        dcache_waddr_o      <= ma_addr_i;
                        dcache_wdata_o      <= wdata_i;
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
                        dcache_we_o         <= `WriteEnable;
                        dcache_waddr_o      <= ma_addr_i;
                        dcache_wdata_o      <= {mem_mem_din_i, data_block3, data_block2, data_block1};
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