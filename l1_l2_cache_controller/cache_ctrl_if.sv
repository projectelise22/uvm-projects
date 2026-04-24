`define TAG_WIDTH 6
`define DATA_WIDTH 32
`define ADDR_WIDTH 8
`define CACHE_SLOT 4

interface cache_ctrl_if;
  logic clk;
  logic rst;
  logic [`ADDR_WIDTH-1:0] addr;
  logic wr_en;
  logic rd_en;
  logic [`DATA_WIDTH-1:0] wdata;
  logic [`DATA_WIDTH-1:0] rdata;
  logic hit;
  logic miss;
endinterface