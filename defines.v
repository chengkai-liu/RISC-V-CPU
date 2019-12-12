// bool
`define RstEnable       1'b1
`define RstDisable      1'b0
`define WriteEnable     1'b1 
`define WriteDisable    1'b0 
`define ReadEnable      1'b1 
`define ReadDisable     1'b0
`define InstValid       1'b1 
`define InstInvalid     1'b0 
`define True_v          1'b1 
`define False_v         1'b0
`define Stop            1'b1
`define NoStop          1'b0

`define ZeroWord        32'h00000000

//----------funct3--------------
`define NOP_FUNCT3      3'b000
`define ADDI_FUNCT3     3'b000
`define ADD_SUB_FUNCT3  3'b000
`define SLT_FUNCT3      3'b010
`define SLTI_FUNCT3     3'b010
`define SLTIU_FUNCT3    3'b011
`define SLTU_FUNCT3     3'b011 
`define XORI_FUNCT3     3'b100
`define XOR_FUNCT3      3'b100
`define ORI_FUNCT3      3'b110
`define OR_FUNCT3       3'b110
`define ANDI_FUNCT3     3'b111
`define AND_FUNCT3      3'b111
`define SLLI_FUNCT3     3'b001
`define SLL_FUNCT3      3'b001
`define SRLI_SRAI_FUNCT3     3'b101
`define SRL_SRA_FUNCT3       3'b101
`define BEQ_FUNCT3      3'b000
`define BNE_FUNCT3      3'b001
`define BLT_FUNCT3      3'b100
`define BGE_FUNCT3      3'b101
`define BLTU_FUNCT3     3'b110
`define BGEU_FUNCT3     3'b111      
`define LB_FUNCT3       3'b000
`define LH_FUNCT3       3'b001
`define LW_FUNCT3       3'b010
`define LBU_FUNCT3      3'b100
`define LHU_FUNCT3      3'b101
`define SB_FUNCT3       3'b000
`define SH_FUNCT3       3'b001
`define SW_FUNCT3       3'b010

//------------AluOp------------------
`define EXE_NOP_OP      8'b00000000
`define EXE_LUI_OP      8'b00000001
`define EXE_AUIPC_OP    8'b00000010
`define EXE_JAL_OP      8'b00000011
`define EXE_JALR_OP     8'b00000100
//BRANCH
`define EXE_BEQ_OP      8'b00000101
`define EXE_BNE_OP      8'b00000110
`define EXE_BLT_OP      8'b00000111
`define EXE_BGE_OP      8'b00001000
`define EXE_BLTU_OP     8'b00001001
`define EXE_BGEU_OP     8'b00001010
//LOAD
`define EXE_LB_OP       8'b00001011
`define EXE_LH_OP       8'b00001100
`define EXE_LW_OP       8'b00001101
`define EXE_LBU_OP      8'b00001110
`define EXE_LHU_OP      8'b00001111
//STORE
`define EXE_SB_OP       8'b00010000
`define EXE_SH_OP       8'b00010001
`define EXE_SW_OP       8'b00010010
//LOGIC
`define EXE_ADD_OP      8'b00010011
`define EXE_SUB_OP      8'b00011100
`define EXE_XOR_OP      8'b00010110
`define EXE_OR_OP       8'b00010111
`define EXE_AND_OP      8'b00011000
//CMP
`define EXE_SLT_OP      8'b00010100
`define EXE_SLTU_OP     8'b00010101
//SHIFT
`define EXE_SLL_OP      8'b00011001
`define EXE_SRL_OP      8'b00011010
`define EXE_SRA_OP      8'b00011011



//-----------AluSel-------------
`define EXE_RES_NOP     3'b000
`define EXE_RES_LOGIC   3'b001
`define EXE_RES_CMP     3'b010
`define EXE_RES_SHIFT   3'b011
`define EXE_RES_JUMP    3'b100
`define EXE_RES_LS      3'b101
`define EXE_RES_LOAD    3'b110
`define EXE_RES_STORE   3'b111


// Bus
`define AluOpBus        7:0
`define AluSelBus       2:0
`define InstAddrBus     31:0
`define InstBus         31:0
`define RegAddrBus      4:0     //the index of register
`define RegBus          31:0    //data
`define DoubleRegBus    63:0
`define StallBus        6:0


`define InstMemNum      131071
`define InstMemNumLog2  17



`define RegWidth        32
`define DoubleRegWidth  64

`define RegNum          32
`define RegNumLog2      5
`define NOPRegAddr      5'b00000
