`include "defines.v"

module inst_rom(
    input wire[`InstAddrBus]        addr,
    output reg[`InstBus]            inst
);

reg[`InstBus] inst_mem[0:`InstMemNum-1];

initial $readmemb("/home/lck/Desktop/data/test.data", inst_mem);

always @ (*) begin
    inst <= inst_mem[addr[`InstMemNumLog2+1:2]];
end

endmodule // inst_rom