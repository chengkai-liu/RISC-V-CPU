`include "openmips.v"
`include "inst_rom.v"

module openmips_min_sopc(
    input wire clk,
    input wire rst
);

wire[`InstAddrBus]      inst_addr;
wire[`InstBus]          inst;

openmips openmips0(
    //input
    .clk(clk),          .rst(rst),
    .rom_data_i(inst),
    //output
    .rom_addr_o(inst_addr)
);

inst_rom inst_rom0(
    //input
    .addr(inst_addr),
    //output
    .inst(inst)
);



endmodule // openmips_min_sopc