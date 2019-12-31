`include "defines.v"
// RISCV32I CPU top module
// port modification allowed for debugging purposes

module cpu(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
    input  wire					        rdy_in,			// ready signal, pause cpu when low

    input  wire [ 7:0]          mem_din,		// data input bus
    output wire [ 7:0]          mem_dout,		// data output bus
    output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
    output wire                 mem_wr,			// write/read signal (1 for write)


	  output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read takes 2 cycles(wait till next cycle), write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

// regfile
wire[`RegBus]           reg1_data;
wire[`RegBus]           reg2_data;

// ctrl
wire[`StallBus]         stall;
wire                    if_ctrl_req;
wire                    mem_ctrl_req;

wire[`InstAddrBus]      if_mem_a;
wire                    mem_mem_wr;
wire[`InstAddrBus]      mem_mem_a;
wire[`DataBus]          mem_mem_dout;


// branch
wire                    branch_flag;
wire[`InstAddrBus]      branch_addr;

// icache input
wire                    icache_we;
wire[`InstAddrBus]      icache_waddr;
wire[`InstBus]          icache_winst;
wire[`InstAddrBus]      icache_raddr; 
// icache output
wire                    icache_hit;
wire[`InstBus]          icache_inst;

// dcache input
wire                    dcache_we;
wire[`InstAddrBus]      dcache_waddr;
wire[`RegBus]           dcache_wdata;
wire[`InstAddrBus]      dcache_raddr;
// dcache output
wire                    dcache_hit;
wire[`RegBus]           dcache_data;

// IF --> IF_ID
wire[`InstAddrBus]      if_pc_o;
wire[`InstBus]          if_inst_o;

// IF_ID --> ID
wire[`InstAddrBus]      id_pc_i;
wire[`InstBus]          id_inst_i;

// regfile --> ID   

// ID --> regfile
wire                    reg1_read;
wire                    reg2_read;
wire[`RegAddrBus]       reg1_addr;
wire[`RegAddrBus]       reg2_addr;

// ID --> ID_EX
wire[`AluOpBus]         id_aluop_o;
wire[`AluSelBus]        id_alusel_o;
wire[`RegBus]           id_reg1_o;
wire[`RegBus]           id_reg2_o;
wire                    id_wreg_o;
wire[`RegAddrBus]       id_wd_o;
wire[`InstAddrBus]      id_jump_link_addr_o;
wire[`RegBus]           id_ls_offset_o;  


// ID_EX --> EX
wire[`AluOpBus]         ex_aluop_i;
wire[`AluSelBus]        ex_alusel_i;
wire[`RegBus]           ex_reg1_i;
wire[`RegBus]           ex_reg2_i;
wire                    ex_wreg_i;
wire[`RegAddrBus]       ex_wd_i;
wire[`RegBus]           ex_jump_link_addr_i;
wire[`InstAddrBus]      ex_ls_offset_i;

// EX --> EX_MEM
wire[`RegAddrBus]       ex_wd_o;
wire                    ex_wreg_o;
wire[`RegBus]           ex_wdata_o;
wire[`AluOpBus]         ex_aluop_o;
wire[`AluSelBus]        ex_alusel_o;
wire[`InstAddrBus]      ex_ma_addr_o;

// EX_MEM --> MEM
wire[`RegAddrBus]       mem_wd_i;
wire                    mem_wreg_i;
wire[`RegBus]           mem_wdata_i;
wire[`AluOpBus]         mem_aluop_i;
wire[`AluSelBus]        mem_alusel_i;
wire[`InstAddrBus]      mem_ma_addr_i;

// MEM --> MEM_WB
wire[`RegAddrBus]       mem_wd_o;
wire                    mem_wreg_o;
wire[`RegBus]           mem_wdata_o;


// MEM_WB --> WB(regfile)
wire                    wb_wreg_i;
wire[`RegAddrBus]       wb_wd_i;
wire[`RegBus]           wb_wdata_i;

regfile regfile0(
    // input
    .clk(clk_in),       .rst(rst_in),       .rdy(rdy_in),
    .we(wb_wreg_i),     .waddr(wb_wd_i),    .wdata(wb_wdata_i),
    .re1(reg1_read),    .raddr1(reg1_addr),
    .re2(reg2_read),    .raddr2(reg2_addr),

    // output
    .rdata1(reg1_data),         .rdata2(reg2_data)
);

stage_if if0(
    // input
    .clk(clk_in),       .rst(rst_in),
    .stall(stall),
    .if_mem_din_i(mem_din),
    .branch_flag_i(branch_flag),    .branch_addr_i(branch_addr),        .alusel_i(id_alusel_o),
    .icache_hit_i(icache_hit),      .icache_inst_i(icache_inst),

    // output
    .pc_o(if_pc_o),                 .inst_o(if_inst_o),
    .if_mem_a_o(if_mem_a),          
    .if_ctrl_req_o(if_ctrl_req),
    .icache_we_o(icache_we),        .icache_waddr_o(icache_waddr),      .icache_winst_o(icache_winst), 
    .icache_raddr_o(icache_raddr)
);

if_id if_id0(
    // input
    .clk(clk_in),       .rst(rst_in),
    .stall(stall),
    .if_pc(if_pc_o),    .if_inst(if_inst_o),

    // output
    .id_pc(id_pc_i),    .id_inst(id_inst_i)
);

stage_id id0(
    // input
    .rst(rst_in),               .rdy(rdy_in),
    .pc_i(id_pc_i),             .inst_i(id_inst_i),
    .reg1_data_i(reg1_data),    .reg2_data_i(reg2_data),
    
    .ex_wreg_i(ex_wreg_o),      .ex_wdata_i(ex_wdata_o),            .ex_wd_i(ex_wd_o),
    .mem_wreg_i(mem_wreg_o),    .mem_wdata_i(mem_wdata_o),          .mem_wd_i(mem_wd_o),
    // output
    .reg1_read_o(reg1_read),    .reg2_read_o(reg2_read),
    .reg1_addr_o(reg1_addr),    .reg2_addr_o(reg2_addr),

    .aluop_o(id_aluop_o),       .alusel_o(id_alusel_o),

    .reg1_o(id_reg1_o),         .reg2_o(id_reg2_o),
    .wreg_o(id_wreg_o),         .wd_o(id_wd_o),

    .jump_link_addr_o(id_jump_link_addr_o),
    .branch_flag_o(branch_flag),    .branch_addr_o(branch_addr),
    .ls_offset_o(id_ls_offset_o)

);

id_ex id_ex0(
    // input
    .clk(clk_in),                   .rst(rst_in),
    .stall(stall),
    .id_aluop(id_aluop_o),          .id_alusel(id_alusel_o),
    .id_reg1(id_reg1_o),            .id_reg2(id_reg2_o),
    .id_wreg(id_wreg_o),            .id_wd(id_wd_o),
    .id_jump_link_addr(id_jump_link_addr_o),
    .id_ls_offset(id_ls_offset_o),
    // output
    .ex_aluop(ex_aluop_i),          .ex_alusel(ex_alusel_i),
    .ex_reg1(ex_reg1_i),            .ex_reg2(ex_reg2_i),
    .ex_wreg(ex_wreg_i),            .ex_wd(ex_wd_i),
    .ex_jump_link_addr(ex_jump_link_addr_i),
    .ex_ls_offset(ex_ls_offset_i)
);

stage_ex ex0(
    // input
    .rst(rst),
    .aluop_i(ex_aluop_i),           .alusel_i(ex_alusel_i),
    .reg1_i(ex_reg1_i),             .reg2_i(ex_reg2_i),
    .wd_i(ex_wd_i),                 .wreg_i(ex_wreg_i),
    
    .jump_link_addr_i(ex_jump_link_addr_i),
    .ls_offset_i(ex_ls_offset_i),
    // output
    .wd_o(ex_wd_o),                 .wreg_o(ex_wreg_o),         .wdata_o(ex_wdata_o),
    .aluop_o(ex_aluop_o),           .alusel_o(ex_alusel_o),
    .ma_addr_o(ex_ma_addr_o)
);

ex_mem ex_mem0(
    // input
    .clk(clk_in),                   .rst(rst_in),
    .stall(stall),
    .ex_wd(ex_wd_o),                .ex_wreg(ex_wreg_o),        .ex_wdata(ex_wdata_o),
    .aluop_i(ex_aluop_o),           .alusel_i(ex_alusel_o),
    .ex_ma_addr(ex_ma_addr_o),
    //output
    .mem_wd(mem_wd_i),              .mem_wreg(mem_wreg_i),      .mem_wdata(mem_wdata_i),
    .aluop_o(mem_aluop_i),          .alusel_o(mem_alusel_i),
    .mem_ma_addr(mem_ma_addr_i)
);

stage_mem mem0(
    // input
    .clk(clk_in),                   .rst(rst_in),
    .aluop_i(mem_aluop_i),          .alusel_i(mem_alusel_i),
    .wd_i(mem_wd_i),                .wreg_i(mem_wreg_i),                .wdata_i(mem_wdata_i),
    .ma_addr_i(mem_ma_addr_i),      .mem_mem_din_i(mem_din),
    .dcache_hit_i(dcache_hit),      .dcache_data_i(dcache_data),
    // output
    .wd_o(mem_wd_o),                .wreg_o(mem_wreg_o),                .wdata_o(mem_wdata_o),
    .mem_ctrl_req_o(mem_ctrl_req),
    .mem_mem_wr_o(mem_mem_wr),      .mem_mem_a_o(mem_mem_a),            .mem_mem_dout_o(mem_mem_dout),
    .dcache_we_o(dcache_we),        .dcache_waddr_o(dcache_waddr),      .dcache_wdata_o(dcache_wdata),
    .dcache_raddr_o(dcache_raddr)
);

mem_wb mem_wb0(
    // input 
    .clk(clk_in),                   .rst(rst_in),
    .stall(stall),
    .mem_wd(mem_wd_o),              .mem_wreg(mem_wreg_o),      .mem_wdata(mem_wdata_o),
    // output
    .wb_wd(wb_wd_i),                .wb_wreg(wb_wreg_i),        .wb_wdata(wb_wdata_i)
);

ctrl ctrl0(
    // input
    .rst(rst_in),                   .rdy(rdy_in),
    .if_ctrl_req_i(if_ctrl_req),    .mem_ctrl_req_i(mem_ctrl_req),
    .if_mem_a_i(if_mem_a),          .mem_mem_a_i(mem_mem_a),
    .mem_mem_wr_i(mem_mem_wr),      .mem_mem_dout_i(mem_mem_dout),
    // output
    .stall(stall),
    .mem_wr_o(mem_wr),              .mem_a_o(mem_a),            .mem_dout_o(mem_dout)
);

icache icache0(
    // input
    .clk(clk_in),                   .rst(rst_in),               .rdy(rdy_in),
    .we_i(icache_we),               .waddr_i(icache_waddr),     .winst_i(icache_winst),
    .raddr_i(icache_raddr),
    // output
    .icache_hit_o(icache_hit),      .icache_inst_o(icache_inst)
);

dcache dcache0(
    // input 
    .clk(clk_in),                   .rst(rst_in),               .rdy(rdy_in),
    .we_i(dcache_we),               .waddr_i(dcache_waddr),     .wdata_i(dcache_wdata),
    .raddr_i(dcache_raddr),
    // output
    .dcache_hit_o(dcache_hit),      .dcache_data_o(dcache_data)
);

endmodule