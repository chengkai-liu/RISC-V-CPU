`include "defines.v"

module stage_ex(
    input wire                      rst,

    input wire[`AluOpBus]           aluop_i,
    input wire[`AluSelBus]          alusel_i,
    input wire[`RegBus]             reg1_i,
    input wire[`RegBus]             reg2_i,
    input wire[`RegAddrBus]         wd_i,
    input wire                      wreg_i,

    input wire[`RegBus]             jump_link_addr_i, 
    input wire[`InstAddrBus]        ls_offset_i,

    output reg[`RegAddrBus]         wd_o,
    output reg                      wreg_o,
    output reg[`RegBus]             wdata_o,

    output reg[`AluOpBus]           aluop_o,
    output reg[`AluSelBus]          alusel_o,

    output reg[`InstAddrBus]        ma_addr_o
);

reg[`RegBus]        logicout;
reg[`RegBus]        cmpres;
reg[`RegBus]        shiftres;

//---------------1-----------------------------------------------------------------
always @ (*) begin
    if (rst == `RstEnable) begin
        logicout <= `ZeroWord;
    end else begin
        case (aluop_i)
            `EXE_ADD_OP: begin
                logicout <= reg1_i + reg2_i;
            end
            `EXE_SUB_OP: begin
                logicout <= reg1_i - reg2_i;
            end
            `EXE_OR_OP: begin
                logicout <= reg1_i | reg2_i;
            end
            `EXE_XOR_OP: begin
                logicout <= reg1_i ^ reg2_i;
            end
            `EXE_AND_OP: begin
                logicout <= reg1_i & reg2_i;
            end
            default: begin
                logicout <= `ZeroWord;
            end
        endcase
    end
end // logic
// ---------------------------------// ---------------------------------

always @ (*) begin
    if (rst == `RstEnable) begin
        cmpres = `ZeroWord;
    end else begin
        case (aluop_i)
            `EXE_SLT_OP: begin
                cmpres <= ($signed(reg1_i) < $signed(reg2_i));
            end
            `EXE_SLTU_OP: begin
                cmpres <= (reg1_i < reg2_i);
            end
            default: begin
                cmpres <= `ZeroWord;
            end
        endcase
    end
end // cmp
// ---------------------------------// ---------------------------------

always @ (*) begin
    if (rst == `RstEnable) begin
        shiftres <= `ZeroWord;
    end else begin
        case (aluop_i)
            `EXE_SLL_OP: begin
                shiftres <= reg1_i << reg2_i[4:0];
            end
            `EXE_SRL_OP: begin
                shiftres <= reg1_i >> reg2_i[4:0];
            end
            `EXE_SRA_OP: begin
                shiftres <= ($signed(reg1_i)) >>> reg2_i[4:0];
            end
            default: begin
                shiftres <= `ZeroWord;
            end
        endcase
    end
end // shift
// ---------------------------------// ---------------------------------

//---------------2-----------------------------------------------------------------
always @ (*) begin
    if (rst == `RstEnable) begin
        aluop_o         <= `EXE_NOP_OP;
        alusel_o        <= `EXE_RES_NOP;
        wd_o            <= `ZeroWord;
        wreg_o          <= `WriteDisable;
        wdata_o         <= `ZeroWord;
    end else begin
        aluop_o         <= aluop_i;
        alusel_o        <= alusel_i;
        wd_o            <= wd_i;
        wreg_o          <= wreg_i;
    end
    case  (alusel_i)
        `EXE_RES_LOGIC: begin
            wdata_o <= logicout;
        end
        `EXE_RES_CMP: begin
            wdata_o <= cmpres;
        end
        `EXE_RES_SHIFT: begin
            wdata_o <= shiftres;
        end
        `EXE_RES_JB: begin
            if (aluop_i == `EXE_JAL_OP || aluop_i == `EXE_JALR_OP) begin
                wdata_o <= jump_link_addr_i;
            end
        end
        `EXE_RES_LOAD: begin
            ma_addr_o   <= reg1_i + ls_offset_i;
        end
        `EXE_RES_STORE: begin
            ma_addr_o   <= reg1_i + ls_offset_i;
            wdata_o     <= reg2_i;
        end
        `EXE_RES_OTHER: begin
            wdata_o     <= reg1_i;
        end
        default: begin
            wdata_o     <= `ZeroWord;
        end
    endcase
end

endmodule // ex