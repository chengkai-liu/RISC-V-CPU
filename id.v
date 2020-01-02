`include "defines.v"

module stage_id(
    input wire                  rst,
    input wire                  rdy,

    input wire[`InstAddrBus]    pc_i,       // pc + 4
    input wire[`InstBus]        inst_i,

    // from regfile
    input wire[`RegBus]         reg1_data_i,
    input wire[`RegBus]         reg2_data_i,

    // from ex for data hazard
    input wire                  ex_wreg_i,
    input wire[`RegBus]         ex_wdata_i,
    input wire[`RegAddrBus]     ex_wd_i,

    // from mem for data hazard
    input wire                  mem_wreg_i,
    input wire[`RegBus]         mem_wdata_i,
    input wire[`RegAddrBus]     mem_wd_i,

    // to regfile
    output reg                  reg1_read_o,
    output reg                  reg2_read_o,
    output reg[`RegAddrBus]     reg1_addr_o,
    output reg[`RegAddrBus]     reg2_addr_o,

    // to ex
    output reg[`AluOpBus]       aluop_o,
    output reg[`AluSelBus]      alusel_o,
    output reg[`RegBus]         reg1_o,
    output reg[`RegBus]         reg2_o,
    output reg                  wreg_o,
    output reg[`RegAddrBus]     wd_o,

/*---------------------jump / branch------------------------*/
    // to ex
    output reg[`InstAddrBus]    jump_link_addr_o,
    // to pc_reg 
    output reg                  branch_flag_o,
    output reg[`InstAddrBus]    branch_addr_o,

/*---------------------load / store--------------------------*/
    // to ex
    output reg[`RegBus]         ls_offset_o 
);

//opcode, funct3, funct7
wire[6:0] op        = inst_i[6:0];
wire[2:0] funct3    = inst_i[14:12];
wire[6:0] funct7    = inst_i[31:25];
//
reg[`RegBus]    imm;
//
reg instvalid;

//------------1. instruction decode----------------
always @ (*) begin
    if (rst == `RstEnable) begin
        aluop_o             <= `EXE_NOP_OP;
        alusel_o            <= `EXE_RES_NOP;
        wd_o                <= `NOPRegAddr;
        wreg_o              <= `WriteDisable;
        instvalid           <= `InstValid;
        reg1_read_o         <= `ReadDisable;
        reg2_read_o         <= `ReadDisable;
        reg1_addr_o         <= `NOPRegAddr;
        reg2_addr_o         <= `NOPRegAddr;
        imm                 <= `ZeroWord;
        jump_link_addr_o    <= `ZeroWord;
        branch_flag_o       <= `NoBranch;
        branch_addr_o       <= `ZeroWord;
        ls_offset_o         <= `ZeroWord;
    end else begin
        aluop_o             <= `EXE_NOP_OP;
        alusel_o            <= `EXE_RES_NOP;
        wd_o                <= inst_i[11:7];
        wreg_o              <= `WriteDisable;
        instvalid           <= `InstInvalid;
        reg1_read_o         <= `ReadDisable;
        reg2_read_o         <= `ReadDisable;
        reg1_addr_o         <= inst_i[19:15];
        reg2_addr_o         <= inst_i[24:20];
        imm                 <= `ZeroWord;
        jump_link_addr_o    <= `ZeroWord;
        branch_flag_o       <= `NoBranch;
        branch_addr_o       <= `ZeroWord;
        ls_offset_o         <= `ZeroWord;
        case (op)
            7'b0110111: begin
                aluop_o             <= `EXE_LUI_OP;
                alusel_o            <= `EXE_RES_OTHER;
                wreg_o              <= `WriteEnable;
                instvalid           <= `InstValid;
                reg1_read_o         <= `ReadDisable;
                reg2_read_o         <= `ReadDisable;
                imm                 <= {inst_i[31:12], 12'b0};
            end // 7'b0110111 LUI
            7'b0010111: begin
                aluop_o             <= `EXE_AUIPC_OP;
                alusel_o            <= `EXE_RES_OTHER;
                wreg_o              <= `WriteEnable;
                instvalid           <= `InstValid;
                reg1_read_o         <= `ReadDisable;
                reg2_read_o         <= `ReadDisable;
                imm                 <= {inst_i[31:12], 12'b0} + pc_i - 4;
            end // 7'b0010111 AUIPC
            7'b1101111: begin
                aluop_o             <= `EXE_JAL_OP;
                alusel_o            <= `EXE_RES_JB;
                wreg_o              <= `WriteEnable;
                instvalid           <= `InstValid;
                reg1_read_o         <= `ReadDisable;
                reg2_read_o         <= `ReadDisable;
                jump_link_addr_o    <= pc_i; 
                branch_flag_o       <= `Branch;
                branch_addr_o       <= pc_i - 4 + {{12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
            end // 7'b1101111 JAL
            7'b1100111: begin
                aluop_o             <= `EXE_JALR_OP;
                alusel_o            <= `EXE_RES_JB;
                wreg_o              <= `WriteEnable;
                instvalid           <= `InstValid;
                reg1_read_o         <= `ReadEnable;
                reg2_read_o         <= `ReadDisable;
                jump_link_addr_o    <= pc_i;
                branch_flag_o       <= `Branch;
                branch_addr_o       <= reg1_o + {{20{inst_i[31]}}, inst_i[31:20]}; 
            end // 7'b1100111 JALR
            7'b1100011: begin
                wreg_o              <= `WriteDisable;
                alusel_o            <= `EXE_RES_JB;
                reg1_read_o         <= `ReadEnable;
                reg2_read_o         <= `ReadEnable;
                instvalid           <= `InstValid;
                case (funct3)
                    `BEQ_FUNCT3: begin
                        aluop_o             <= `EXE_BEQ_OP;
                        if (reg1_o == reg2_o) begin
                            branch_flag_o       <= `Branch;
                            branch_addr_o   <= pc_i - 4 + {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
                        end else begin
                            branch_flag_o       <= `NoBranch;
                            branch_addr_o   <= pc_i;
                        end
                    end
                    `BNE_FUNCT3: begin
                        aluop_o             <= `EXE_BNE_OP;
                        if (reg1_o != reg2_o) begin
                            branch_flag_o       <= `Branch;
                            branch_addr_o   <= pc_i - 4 + {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
                        end else begin
                            branch_flag_o       <= `NoBranch;
                            branch_addr_o   <= pc_i;
                        end
                    end
                    `BLT_FUNCT3: begin
                        aluop_o             <= `EXE_BLT_OP;
                        if ($signed(reg1_o) < $signed(reg2_o)) begin   
                            branch_flag_o       <= `Branch;
                            branch_addr_o   <= pc_i - 4 + {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
                        end else begin
                            branch_flag_o       <= `NoBranch;
                            branch_addr_o   <= pc_i;
                        end
                    end
                    `BGE_FUNCT3: begin
                        aluop_o             <= `EXE_BGE_OP;
                        if (!($signed(reg1_o) < $signed(reg2_o))) begin
                            branch_flag_o       <= `Branch;
                            branch_addr_o   <= pc_i - 4 + {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
                        end else begin
                            branch_flag_o       <= `NoBranch;
                            branch_addr_o   <= pc_i;
                        end
                    end
                    `BLTU_FUNCT3: begin
                        aluop_o             <= `EXE_BLTU_OP;
                        if (reg1_o < reg2_o) begin
                            branch_flag_o       <= `Branch;
                            branch_addr_o   <= pc_i - 4 + {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
                        end else begin
                            branch_flag_o       <= `NoBranch;
                            branch_addr_o   <= pc_i;
                        end
                    end
                    `BGEU_FUNCT3: begin
                        aluop_o             <= `EXE_BGEU_OP;
                        if (!(reg1_o < reg2_o)) begin
                            branch_flag_o       <= `Branch;
                            branch_addr_o   <= pc_i - 4 + {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
                        end else begin
                            branch_flag_o       <= `NoBranch;
                            branch_addr_o   <= pc_i;
                        end
                    end
                    default: begin
                    end
                endcase
            end // 7'b1100011 BRANCH
            7'b0000011: begin
                alusel_o        <= `EXE_RES_LOAD;
                wreg_o          <= `WriteEnable;
                instvalid       <= `InstValid;
                reg1_read_o     <= `ReadEnable;
                reg2_read_o     <= `ReadDisable;
                ls_offset_o     <= {{20{inst_i[31]}}, inst_i[31:20]};
                case (funct3) 
                    `LB_FUNCT3: begin
                        aluop_o     <= `EXE_LB_OP;
                    end
                    `LH_FUNCT3: begin
                        aluop_o     <= `EXE_LH_OP;
                    end
                    `LW_FUNCT3: begin
                        aluop_o     <= `EXE_LW_OP;
                    end
                    `LBU_FUNCT3: begin
                        aluop_o     <= `EXE_LBU_OP;
                    end
                    `LHU_FUNCT3: begin
                        aluop_o     <= `EXE_LHU_OP;
                    end
                    default: begin
                    end
                endcase
            end // 7'b0000011 LOAD
            7'b0100011: begin
                alusel_o        <= `EXE_RES_STORE;
                wreg_o          <= `WriteDisable;
                instvalid       <= `InstValid;
                reg1_read_o     <= `ReadEnable;
                reg2_read_o     <= `ReadEnable;
                ls_offset_o     <= {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
                case (funct3)
                    `SB_FUNCT3: begin
                        aluop_o     <= `EXE_SB_OP;
                    end
                    `SW_FUNCT3: begin
                        aluop_o     <= `EXE_SW_OP;
                    end
                    `SH_FUNCT3: begin
                        aluop_o     <= `EXE_SH_OP;
                    end
                    default: begin
                    end
                endcase
            end // 7'b0100011 STORE
            7'b0010011: begin
                wreg_o          <= `WriteEnable;
                instvalid       <= `InstValid;
                reg1_read_o     <= `ReadEnable;
                reg2_read_o     <= `ReadDisable;
                case (funct3)
                    `ADDI_FUNCT3: begin
                        aluop_o         <= `EXE_ADD_OP;
                        alusel_o        <= `EXE_RES_LOGIC;
                        imm             <= {{20{inst_i[31]}}, inst_i[31:20]};
                    end
                    `SLTI_FUNCT3: begin
                        aluop_o         <= `EXE_SLT_OP;
                        alusel_o        <= `EXE_RES_CMP;
                        imm             <= {{20{inst_i[31]}}, inst_i[31:20]};
                    end 
                    `SLTIU_FUNCT3: begin
                        aluop_o         <= `EXE_SLTU_OP;
                        alusel_o        <= `EXE_RES_CMP;
                        imm             <= {{20{inst_i[31]}}, inst_i[31:20]};
                    end
                    `XORI_FUNCT3: begin
                        aluop_o         <= `EXE_XOR_OP;
                        alusel_o        <= `EXE_RES_LOGIC;
                        imm             <= {{20{inst_i[31]}}, inst_i[31:20]};
                    end 
                    `ORI_FUNCT3: begin
                        aluop_o         <= `EXE_OR_OP;
                        alusel_o        <= `EXE_RES_LOGIC;
                        imm             <= {{20{inst_i[31]}}, inst_i[31:20]};
                    end 
                    `ANDI_FUNCT3: begin
                        aluop_o         <= `EXE_AND_OP;
                        alusel_o        <= `EXE_RES_LOGIC;
                        imm             <= {{20{inst_i[31]}}, inst_i[31:20]};
                    end
                    `SLLI_FUNCT3: begin
                        aluop_o         <= `EXE_SLL_OP;
                        alusel_o        <= `EXE_RES_SHIFT;
                        imm             <= {27'h0, inst_i[24:20]};
                    end
                    `SRLI_SRAI_FUNCT3: begin
                        alusel_o        <= `EXE_RES_SHIFT;
                        imm             <= {27'h0, inst_i[24:20]};
                        if (inst_i[30] == 1'b0) begin
                            aluop_o     <= `EXE_SRL_OP;
                        end else begin
                            aluop_o     <= `EXE_SRA_OP;
                        end
                    end
                    default: begin
                    end
               endcase
            end // 7'b0010011
            7'b0110011: begin
                wreg_o              <= `WriteEnable;
                instvalid           <= `InstValid;
                reg1_read_o         <= `ReadEnable;
                reg2_read_o         <= `ReadEnable;
                imm                 <= `ZeroWord;
                case (funct3)
                    `ADD_SUB_FUNCT3: begin
                        alusel_o        <= `EXE_RES_LOGIC;
                        if (inst_i[30] == 1'b0) begin
                            aluop_o     <= `EXE_ADD_OP;
                        end else begin
                            aluop_o     <= `EXE_SUB_OP;
                        end
                    end
                    `SLL_FUNCT3: begin
                        aluop_o         <= `EXE_SLL_OP;
                        alusel_o        <= `EXE_RES_SHIFT;
                    end
                    `SLT_FUNCT3: begin
                        aluop_o         <= `EXE_SLT_OP;
                        alusel_o        <= `EXE_RES_CMP;
                    end
                    `SLTU_FUNCT3: begin
                        aluop_o         <= `EXE_SLTU_OP;
                        alusel_o        <= `EXE_RES_CMP;
                    end
                    `XOR_FUNCT3: begin
                        aluop_o         <= `EXE_XOR_OP;
                        alusel_o        <= `EXE_RES_LOGIC;
                    end
                    `SRL_SRA_FUNCT3: begin
                        alusel_o        <= `EXE_RES_SHIFT;
                        if (inst_i[30] == 1'b0) begin
                            aluop_o     <= `EXE_SRL_OP;
                        end else begin
                            aluop_o     <= `EXE_SRA_OP;
                        end
                    end
                    `OR_FUNCT3: begin
                        aluop_o         <= `EXE_OR_OP;
                        alusel_o        <= `EXE_RES_LOGIC;
                    end
                    `AND_FUNCT3: begin
                        aluop_o         <= `EXE_AND_OP;
                        alusel_o        <= `EXE_RES_LOGIC;
                    end
                    default: begin
                end
                endcase 
            end // 7'b0110011
            default: begin
            end
        endcase
    end
end

//--------------2. reg1----------------
always @ (*) begin
    if (rst == `RstEnable) begin
        reg1_o <= `ZeroWord;
    end else if (rdy == `IsReady) begin
        if ((reg1_read_o == `ReadEnable) && (ex_wreg_i == `ReadEnable) && (ex_wd_i == reg1_addr_o)) begin
            reg1_o <= ex_wdata_i;
        end else if ((reg1_read_o == `ReadEnable) && (mem_wreg_i == `ReadEnable) && (mem_wd_i == reg1_addr_o)) begin
            reg1_o <= mem_wdata_i;
        end else if (reg1_read_o == `ReadEnable) begin
            reg1_o <= reg1_data_i;
        end else if (reg1_read_o == `ReadDisable) begin
            reg1_o <= imm;
        end else begin
            reg1_o <= `ZeroWord;
        end
    end
end

//--------------3. reg2------------------
always @ (*) begin
    if (rst == `RstEnable) begin
        reg2_o <= `ZeroWord;
    end else if (rdy == `IsReady) begin
        if ((reg2_read_o == `ReadEnable) && (ex_wreg_i == `ReadEnable) && (ex_wd_i == reg2_addr_o)) begin
            reg2_o <= ex_wdata_i;
        end else if ((reg2_read_o == `ReadEnable) && (mem_wreg_i == `ReadEnable) && (mem_wd_i == reg2_addr_o)) begin
            reg2_o <= mem_wdata_i;
        end else if (reg2_read_o == `ReadEnable) begin
            reg2_o <= reg2_data_i;
        end else if (reg2_read_o == `ReadDisable) begin
            reg2_o <= imm;
        end else begin
            reg2_o <= `ZeroWord;
        end
    end
end

endmodule // id