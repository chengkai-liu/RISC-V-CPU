`include "defines.v"

module id(
    input wire                  rst,
    input wire[`InstAddrBus]    pc_i,
    input wire[`InstBus]        inst_i,

    //read from regfile
    input wire[`RegBus]         reg1_data_i,
    input wire[`RegBus]         reg2_data_i,

    //output to regfile
    output reg                  reg1_read_o,
    output reg                  reg2_read_o,
    output reg[`RegAddrBus]     reg1_addr_o,
    output reg[`RegAddrBus]     reg2_addr_o,

    //send to EX stage
    output reg[`AluOpBus]       aluop_o,
    output reg[`AluSelBus]      alusel_o,
    output reg[`RegBus]         reg1_o,
    output reg[`RegBus]         reg2_o,
    output reg                  wreg_o,
    output reg[`RegAddrBus]     wd_o,

    //branch
    output reg[`RegBus]         link_addr_o,
    output reg                  branch_flag_o,
    output reg[`RegBus]         branch_addr_o
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
        aluop_o <= `EXE_NOP_OP;
        alusel_o <= `EXE_RES_NOP;
        wd_o <= `NOPRegAddr;
        wreg_o <= `WriteDisable;
        instvalid <= `InstValid;
        reg1_read_o <= 1'b0;
        reg2_read_o <= 1'b0;
        reg1_addr_o <= `NOPRegAddr;
        reg2_addr_o <= `NOPRegAddr;
        imm <= 32'h0;
    end else begin
        aluop_o <= `EXE_NOP_OP;
        alusel_o <= `EXE_RES_NOP;
        wd_o <= inst_i[11:7];
        wreg_o <= `WriteDisable;
        instvalid <= `InstInvalid;
        reg1_read_o <= 1'b0;
        reg2_read_o <= 1'b0;
        reg1_addr_o <= inst_i[19:15];
        reg2_addr_o <= inst_i[24:20];
        imm <= 32'h0;
        link_addr_o <= `ZeroWord;
        branch_flag_o <= 1'b0;
        branch_addr_o <= `ZeroWord;

        case (op)
            7'b0110111: begin
                //todo LUI
            end // 7'b0110111 LUI
            7'b0010111: begin
                //todo AUIPC
            end // 7'b0010111 AUIPC
            7'b1101111: begin
                aluop_o <= `EXE_JAL_OP;
                alusel_o <= `EXE_RES_JUMP;
                wreg_o <= `WriteEnable;
                instvalid <= `InstValid;
                reg1_read_o <= 1'b0;
                reg2_read_o <= 1'b0;
                link_addr_o <= pc_i + 4; //link_addr_o
                branch_flag_o <= 1'b1;
                branch_addr_o <= pc_i + {{12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
            end // 7'b1101111
            7'b1100111: begin
                aluop_o <= `EXE_JALR_OP;
                alusel_o <= `EXE_RES_JUMP;
                wreg_o <= `WriteEnable;
                instvalid <= `InstValid;
                reg1_read_o <= 1'b1;
                reg2_read_o <= 1'b0;
                link_addr_o <= pc_i + 4;
                branch_flag_o <= 1'b1;
                branch_addr_o <= reg1_o + {20'b0, inst_i[31:20]}; //todo unsure
            end // 7'b1100111
            7'b1100011: begin
                case (funct3)
                    `BEQ_FUNCT3: begin
                        wreg_o <= `WriteDisable;
                        aluop_o <= `EXE_BEQ_OP;
                        alusel_o <= `EXE_RES_JUMP;
                        reg1_read_o <= 1'b1;
                        reg2_read_o <= 1'b1;
                        instvalid <= `InstValid;
                        branch_flag_o <= 1'b1;
                        if (reg1_o == reg2_o) begin
                            branch_addr_o <= pc_i + {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
                        end else begin
                            branch_addr_o <= pc_i + 4;
                        end
                    end
                    `BNE_FUNCT3: begin
                        wreg_o <= `WriteDisable;
                        aluop_o <= `EXE_BNE_OP;
                        alusel_o <= `EXE_RES_JUMP;
                        reg1_read_o <= 1'b1;
                        reg2_read_o <= 1'b1;
                        instvalid <= `InstValid;
                        branch_flag_o <= 1'b1;
                        if (reg1_o != reg2_o) begin
                            branch_addr_o <= pc_i + {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
                        end else begin
                            branch_addr_o <= pc_i + 4;
                        end
                    end
                    `BLT_FUNCT3: begin
                        wreg_o <= `WriteDisable;
                        aluop_o <= `EXE_BLT_OP;
                        alusel_o <= `EXE_RES_JUMP;
                        reg1_read_o <= 1'b1;
                        reg2_read_o <= 1'b1;
                        instvalid <= `InstValid;
                        branch_flag_o <= 1'b1;
                        if ($signed(reg1_o) < $signed(reg2_o)) begin
                            branch_addr_o <= pc_i + {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
                        end else begin
                            branch_addr_o <= pc_i + 4;
                        end
                    end
                    `BGE_FUNCT3: begin
                        wreg_o <= `WriteDisable;
                        aluop_o <= `EXE_BGE_OP;
                        alusel_o <= `EXE_RES_JUMP;
                        reg1_read_o <= 1'b1;
                        reg2_read_o <= 1'b1;
                        instvalid <= `InstValid;
                        branch_flag_o <= 1'b1;
                        if (!($signed(reg1_o) < $signed(reg2_o))) begin
                            branch_addr_o <= pc_i + {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
                        end else begin
                            branch_addr_o <= pc_i + 4;
                        end
                    end
                    `BLTU_FUNCT3: begin
                        wreg_o <= `WriteDisable;
                        aluop_o <= `EXE_BLTU_OP;
                        alusel_o <= `EXE_RES_JUMP;
                        reg1_read_o <= 1'b1;
                        reg2_read_o <= 1'b1;
                        instvalid <= `InstValid;
                        branch_flag_o <= 1'b1;
                        if (reg1_o < reg2_o) begin
                            branch_addr_o <= pc_i + {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
                        end else begin
                            branch_addr_o <= pc_i + 4;
                        end
                    end
                    `BGEU_FUNCT3: begin
                        wreg_o <= `WriteDisable;
                        aluop_o <= `EXE_BGEU_OP;
                        alusel_o <= `EXE_RES_JUMP;
                        reg1_read_o <= 1'b1;
                        reg2_read_o <= 1'b1;
                        instvalid <= `InstValid;
                        branch_flag_o <= 1'b1;
                        if (!(reg1_o < reg2_o)) begin
                            branch_addr_o <= pc_i + {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
                        end else begin
                            branch_addr_o <= pc_i + 4;
                        end
                    end
                    
                endcase
            end // 7'b1100011 BRANCH
            7'b0000011: begin
                //todo LOAD
            end // 7'b0000011 LOAD
            7'b0100011: begin
                //todo STORE
            end // 7'b0100011 STORE
            7'b0010011: begin
                wreg_o <= `WriteEnable;
                instvalid <= `InstValid;
                reg1_read_o <= 1'b1;
                reg2_read_o <= 1'b0;
                case (funct3)
                    `ADDI_FUNCT3: begin
                        aluop_o <= `EXE_ADD_OP;
                        alusel_o <= `EXE_RES_LOGIC;
                        imm <= {{20{inst_i[31]}}, inst_i[31:20]};
                    end
                    `SLTI_FUNCT3: begin
                        aluop_o <= `EXE_SLT_OP;
                        alusel_o <= `EXE_RES_CMP;
                        imm <= {{20{inst_i[31]}}, inst_i[31:20]};
                    end 
                    `SLTIU_FUNCT3: begin
                        aluop_o <= `EXE_SLTU_OP;
                        alusel_o <= `EXE_RES_CMP;
                        imm <= {{20{inst_i[31]}}, inst_i[31:20]};
                    end
                    `XORI_FUNCT3: begin
                        aluop_o <= `EXE_XOR_OP;
                        alusel_o <= `EXE_RES_LOGIC;
                        imm <= {{20{inst_i[31]}}, inst_i[31:20]};
                    end
                    `ORI_FUNCT3: begin
                        aluop_o <= `EXE_OR_OP;
                        alusel_o <= `EXE_RES_LOGIC;
                        imm <= {{20{inst_i[31]}}, inst_i[31:20]};
                    end 
                    `ANDI_FUNCT3: begin
                        aluop_o <= `EXE_AND_OP;
                        alusel_o <= `EXE_RES_LOGIC;
                        imm <= {{20{inst_i[31]}}, inst_i[31:20]};
                    end
                    `SLLI_FUNCT3: begin
                        aluop_o <= `EXE_SLL_OP;
                        alusel_o <= `EXE_RES_SHIFT;
                        imm <= {27'h0, inst_i[24:20]};
                    end
                    `SRLI_SRAI_FUNCT3: begin
                        alusel_o <= `EXE_RES_SHIFT;
                        imm <= {27'h0, inst_i[24:20]};
                        if (inst_i[30] == 1'b0) begin
                            aluop_o <= `EXE_SRL_OP;
                        end else begin
                            aluop_o <= `EXE_SRA_OP;
                        end
                    end
               endcase
            end // 7'b0010011
            7'b0110011: begin
                wreg_o <= `WriteEnable;
                instvalid <= `InstValid;
                reg1_read_o <= 1'b1;
                reg2_read_o <= 1'b1;
                imm <= `ZeroWord;
                case (funct3)
                    `ADD_SUB_FUNCT3: begin
                        alusel_o <= `EXE_RES_LOGIC;
                        if (inst_i[30] == 1'b0) begin
                            aluop_o <= `EXE_ADD_OP;
                        end else begin
                            aluop_o <= `EXE_SUB_OP;
                        end
                    end
                    `SLL_FUNCT3: begin
                        aluop_o <= `EXE_SLL_OP;
                        alusel_o <= `EXE_RES_SHIFT;
                    end
                    `SLT_FUNCT3: begin
                        aluop_o <= `EXE_SLT_OP;
                        alusel_o <= `EXE_RES_CMP;
                    end
                    `SLTU_FUNCT3: begin
                        aluop_o <= `EXE_SLTU_OP;
                        alusel_o <= `EXE_RES_CMP;
                    end
                    `XOR_FUNCT3: begin
                        aluop_o <= `EXE_XOR_OP;
                        alusel_o <= `EXE_RES_LOGIC;
                    end
                    `SRL_SRA_FUNCT3: begin
                        alusel_o <= `EXE_RES_SHIFT;
                        if (inst_i[30] == 1'b0) begin
                            aluop_o <= `EXE_SRL_OP;
                        end else begin
                            aluop_o <= `EXE_SRA_OP;
                        end
                    end
                    `OR_FUNCT3: begin
                        aluop_o <= `EXE_OR_OP;
                        alusel_o <= `EXE_RES_LOGIC;
                    end
                    `AND_FUNCT3: begin
                        aluop_o <= `EXE_AND_OP;
                        alusel_o <= `EXE_RES_LOGIC;
                    end
                endcase 
            end // 7'b0110011
            default: begin
                //none
            end
        endcase
    end
end

//--------------2. reg1----------------
always @ (*) begin
    if (rst == `RstEnable) begin
        reg1_o <= `ZeroWord;
    end else if (reg1_read_o == 1'b1) begin
        reg1_o <= reg1_data_i;
    end else if (reg1_read_o == 1'b0) begin
        reg1_o <= imm;
    end else begin
        reg1_o <= `ZeroWord;
    end
end

//--------------3. reg2------------------
always @ (*) begin
    if (rst == `RstEnable) begin
        reg2_o <= `ZeroWord;
    end else if (reg2_read_o == 1'b1) begin
        reg2_o <= reg2_data_i;
    end else if (reg2_read_o == 1'b0) begin
        reg2_o <= imm;
    end else begin
        reg2_o <= `ZeroWord;
    end
end

endmodule // id