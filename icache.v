`include "defines.v"
// lec01 p51
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

// 4*BlockNum Byte Direct Mapped Cache

reg                     valid_bit[`BlockNum - 1:0];
reg[`TagBus]            cache_tag[`BlockNum - 1:0];    
reg[`InstBus]           cache_data[`BlockNum - 1:0];

//
wire[`IndexBus]         rindex_i;
wire[`TagBus]           rtag_i;

assign rindex_i         = rpc_i[`BlockNumLog2 - 1:0];
assign rtag_i           = rpc_i[17:`BlockNumLog2];

//
wire[`IndexBus]         windex_i;
wire[`TagBus]           wtag_i;

assign windex_i         = wpc_i[`BlockNumLog2 - 1:0];
assign wtag_i           = wpc_i[17:`BlockNumLog2];

//
wire                    r_valid;
wire[`TagBus]           r_cache_tag;
wire[`InstBus]          r_cache_inst;

assign r_valid          = valid_bit[rindex_i];
assign r_cache_tag      = cache_tag[rindex_i];
assign r_cache_inst     = cache_data[rindex_i];

//
integer i;
always @ (posedge clk) begin
    if (rst == `RstEnable) begin
        for (i = 0; i < `BlockNum; i = i + 1) begin
            valid_bit[i]            <= `Invalid;
        end
    end else if (we_i) begin
        valid_bit[windex_i]         <= `Valid;
        cache_tag[windex_i]         <= wtag_i;
        cache_data[windex_i]        <= winst_i;
    end
end

//
always @ (*) begin
    if (rst == `RstEnable || rdy == `NotReady) begin
        cache_hit_o                 <= `Miss;
        cache_inst_o                <= `ZeroWord;
    end else begin
        if ((rindex_i == windex_i) && we_i == `True_v) begin
            cache_hit_o             <= `Hit;
            cache_inst_o            <= winst_i;
        end else if ((rtag_i == r_cache_tag) && r_valid == `Valid) begin
            cache_hit_o             <= `Hit;
            cache_inst_o            <= r_cache_inst;
        end else begin
            cache_hit_o             <= `Miss;
            cache_inst_o            <= `ZeroWord;
        end
    end
end

// todo

endmodule // icache