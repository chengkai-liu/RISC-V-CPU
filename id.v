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
    output reg[`RegAddrBus]     wd_o
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
        wd_o <= inst_i[11:7];
        reg1_addr_o <= inst_i[19:15];
        reg2_addr_o <= inst_i[24:20];
        case (op)
            7'b0010011: begin
                case (funct3)
                    `ORI_FUNCT3: begin
                        aluop_o <= `EXE_OR_OP;
                        alusel_o <= `EXE_RES_LOGIC;
                        wreg_o <= `WriteEnable;
                        instvalid <= `InstValid;
                        reg1_read_o <= 1'b1;
                        reg2_read_o <= 1'b0;
                        imm <= {{20{inst_i[31]}}, inst_i[31:20]};
                    end 
               endcase
            end
            default: begin
                aluop_o <= `EXE_NOP_OP;
                alusel_o <= `EXE_RES_NOP;
                wreg_o <= `WriteDisable;
                instvalid <= `InstValid;
                reg1_read_o <= 1'b0;
                reg2_read_o <= 1'b0;
                imm <= `ZeroWord;
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