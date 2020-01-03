`include "defines.v"

module dcache(
    input wire                      clk,
    input wire                      rst,
    input wire                      rdy,

    input wire                      we_i,
    input wire[`InstAddrBus]        waddr_i,
    input wire[`RegBus]             wdata_i,

    input wire[`InstAddrBus]        raddr_i,

    output reg                      dcache_hit_o,
    output reg[`RegBus]             dcache_data_o
);

reg                 valid_bit[`BlockNum - 1:0];
reg[`TagBus]        cache_tag[`BlockNum - 1:0];
reg[`InstBus]       cache_data[`BlockNum - 1:0];

//
wire[`IndexBus]     rindex_i;
wire[`TagBus]       rtag_i;

assign rindex_i     = raddr_i[`BlockNumLog2 - 1:0];
assign rtag_i       = raddr_i[17:`BlockNumLog2];

//
wire[`IndexBus]         windex_i;
wire[`TagBus]           wtag_i;

assign windex_i         = waddr_i[`BlockNumLog2 - 1:0];
assign wtag_i           = waddr_i[17:`BlockNumLog2];

//
wire                    r_valid;
wire[`TagBus]           r_cache_tag;
wire[`InstBus]          r_cache_data;

assign r_valid          = valid_bit[rindex_i];
assign r_cache_tag      = cache_tag[rindex_i];
assign r_cache_data     = cache_data[rindex_i];

//
integer i;
always @ (posedge clk) begin
    if (rst == `RstEnable) begin
        for (i = 0; i < `BlockNum; i = i + 1) begin
            valid_bit[i]            <= `Invalid;
        end
    end else if (we_i == `WriteEnable) begin
        valid_bit[windex_i]         <= `Valid;
        cache_tag[windex_i]         <= waddr_i[17:`BlockNumLog2];
        cache_data[windex_i]        <= wdata_i;
    end
end

//
always @ (*) begin
    if (rst == `RstEnable || rdy == `NotReady) begin
        dcache_hit_o                <= `Miss;
        dcache_data_o               <= `ZeroWord;
    end else begin
        if ((rindex_i == windex_i) && we_i == `WriteEnable) begin
            dcache_hit_o            <= `Hit;
            dcache_data_o           <= wdata_i;
        end else if ((rtag_i == r_cache_tag) && r_valid == `Valid) begin
            dcache_hit_o            <= `Hit;
            dcache_data_o           <= r_cache_data;
        end else begin
            dcache_hit_o            <= `Miss;
            dcache_data_o           <= `ZeroWord;
        end
    end
end


endmodule // dcache