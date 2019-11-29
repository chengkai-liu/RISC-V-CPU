`include "defines.v"

module ex(
    input wire          rst,

    input wire[`AluOpBus]           aluop_i,
    input wire[`AluSelBus]          alusel_i,
    input wire[`RegBus]             reg1_i,
    input wire[`RegBus]             reg2_i,
    input wire[`RegAddrBus]         wd_i,
    input wire                      wreg_i,

    output reg[`RegAddrBus]         wd_o,
    output reg                      wreg_o,
    output reg[`RegBus]             wdata_o
);

reg[`RegBus]        logicout;
reg[`RegBus]        cmpres;
reg[`RegBus]        shiftres;

//---------------1-----------------
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

//---------------2-----------------
always @ (*) begin
    wd_o <= wd_i;
    wreg_o <= wreg_i;
    case  (alusel_i)
        `EXE_RES_LOGIC: begin
            wdata_o <= logicout;
        end
        `EXE_RES_CMP: begin
            //todo unsure
            wdata_o <= cmpres;
        end
        `EXE_RES_SHIFT: begin
            wdata_o <= shiftres;
        end
        default: begin
            wdata_o <= `ZeroWord;
        end
    endcase
end

endmodule // ex