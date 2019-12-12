`include "defines.v"

module icache(
    input wire                      clk,
    input wire                      rst,
    input wire                      rdy,

    input wire                      we_i,
    input wire[`InstAddrBus]        wpc_i,
    input wire[`InstBus]            winst_i,

    input wire[`InstAddrBus]        rpc_i,

    output reg                      cache_hit_o,
    output reg[`InstBus]            cache_inst_o
);

// todo

endmodule // icache