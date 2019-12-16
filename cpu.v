`include "regfile.v"
`include "if.v"
`include "if_id.v"
`include "id.v"
`include "id_ex.v"
`include "ex.v"
`include "ex_mem.v"
`include "mem.v"
`include "mem_wb.v"
`include "ctrl.v"
`include "icache.v"
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

// ctrl
wire[`StallBus]         stall;
wire                    if_ctrl_req;
wire                    mem_ctrl_req;

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


// MEM_WB --> WB(regfile)
wire                    wb_wreg_i;
wire[`RegAddrBus]       wb_wd_i;
wire[`RegBus]           wb_wdata_i;

regfile regfile0(
    // input
    .clk(clk_in),       .rst(rst_in),       .rdy(rdy_in),
    .we(wb_wd_i),       .waddr(wb_wreg_i),  .wdata(wb_wdata_i),
    .re1(reg1_read),    .raddr1(reg1_addr),
    .re2(reg2_read),    .raddr2(reg2_addr),

    // output
    .rdata1(reg1_data),         .rdata2(reg2_data)
);

stageif if0(
    // input
    .clk(clk_in),       .rst(rst_in),
    .stall(stall),
    .if_mem_din_i(mem_din),
    .branch_flag_i(branch_flag),    .branch_addr_i(branch_addr),
    .icache_hit_i(icache_hit),      .icache_inst_i(icache_inst),

    // output
    .pc_o(if_pc_o),                 .inst_o(if_inst_o),
    .if_mem_a_o(mem_dout),          
    .if_ctrl_req_o(if_ctrl_req),
    .icache_we_o(icache_we),        .icache_waddr_o(icache_waddr),      .icache_winst_o(icache_winst), 
    .icache_raddr_o(icache_raddr)
);

if_id if_id0(
    // input
    .clk(lck_in),       .rst(rst_in),
    .stall(stall),
    .if_pc(if_pc_o),    .if_inst(if_inst_o),

    // output
    .id_pc(id_pc_i),    .id_inst(id_inst_i)
);

stageid id0(
    // input
    .rst(rst_in),               .rdy(rdy_in),
    .pc_i(id_pc_i),             .inst_i(id_inst_i),
    .reg1_data_i(reg1_data),    .reg2_data_i(reg2_data),
    // todo
    .ex_wreg_i(),               .ex_wdata_i(),          .ex_wd_i(),
    .mem_wreg_i(),              .mem_wdata_i(),         .mem_wd_i(),
    // output
    .reg1_read_o(reg1_read),    .reg2_read_o(reg2_read),
    .reg1_addr_o(reg1_addr),    .reg2_addr_o(reg2_addr),

    .aluop_o(id_aluop_o),       .alusel_o(id_alusel_o),

    .reg1_o(id_reg1_o),         .reg2_o(id_reg2_o),
    .wreg_o(id_wreg_o),         .wd_o(id_wd_o)

    // todo
    .jump_link_addr_o()
);

// todo
id_ex id_ex0(
    // input
    .clk(clk_in),                   .rst(rst_in),
    .stall(stall),
    .id_aluop(id_aluop_o),          .id_alusel(id_alusel_o),
    .id_reg1(id_reg1_o),            .id_reg2(id_reg2_o),
    .id_wreg(id_wreg_o),            .id_wd(id_wd_o),
    // output
);

stageex ex0(

);

stagemem mem0(

);

endmodule