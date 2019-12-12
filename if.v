`include "defines.v"

module if(
    input wire                      clk,
    input wire                      rst,

    // from ctrl
    input wire[`StallBus]           stall,

    // data input from cpu.v
    input wire[`DataBus]            mem_din_i,

    // from id branch
    input wire                      branch_flag_i,
    input wire[`InstAddrBus]        branch_addr_i,

    output reg                      pc_o,
    output reg[`InstBus]            inst_o,

    // to ctrl  todo: branch prediction
    output reg                      branch_stall_req_o,
    // todo
    output reg                      if_mctrl_req_o,

    // to mctrl
    output reg                      mctrl_we_o,
    output reg[`InstAddrBus]        mctrl_addr_o,

    // to icahce
    output reg                      icache_we_o,
    output reg[`InstAddrBus]        icache_waddr_o,
    output reg[`InstBus]            icache_winst_o,

    output reg[`InstAddrBus]        icache_raddr_o,
);

reg[3:0]        cnt;
reg[`DataBus]   inst_block1;
reg[`DataBus]   inst_block2;
reg[`DataBus]   inst_block3;



endmodule // if