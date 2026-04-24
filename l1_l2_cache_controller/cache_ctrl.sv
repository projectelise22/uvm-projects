`define TAG_WIDTH 6
`define DATA_WIDTH 32
`define ADDR_WIDTH 8
`define CACHE_SLOT 4

module cache_ctrl#(parameter int ADDR_WIDTH = `ADDR_WIDTH,
                   parameter int DATA_WIDTH = `DATA_WIDTH)(
  input logic clk,
  input logic rst,
  input logic [ADDR_WIDTH-1:0] addr,
  input logic wr_en,
  input logic rd_en,
  input logic [DATA_WIDTH-1:0] wdata,
  output logic [DATA_WIDTH-1:0] rdata,
  output logic hit,
  output logic miss
);
  
  // DUT Registers
  // Registers for 4 cache line
  logic valid                  [`CACHE_SLOT];
  logic dirty                  [`CACHE_SLOT];
  logic [`TAG_WIDTH-1:0] tag   [`CACHE_SLOT];
  logic [`DATA_WIDTH-1:0] data [`CACHE_SLOT];
  
  // tag
  logic [$clog2(`CACHE_SLOT)-1:0] index;
  logic [(`TAG_WIDTH-$clog2(`CACHE_SLOT))-1:0] addr_tag;
  
  assign index = addr[$clog2(`CACHE_SLOT)-1:0];
  assign addr_tag = addr[`ADDR_WIDTH-1:$clog2(`CACHE_SLOT)];
  
  // hit and miss logic
  assign hit = valid[index] && (tag[index] == addr_tag);
  assign miss = ~hit;
  
  // read logic
  assign rdata = (rd_en && hit) ? data[index] : `DATA_WIDTH'b0;
  
  // write and miss handling
  always_ff @(posedge clk or posedge rst) begin
    
    if (rst) begin
      // On reset, mark all slots as empty
      for(int i=0; i<`CACHE_SLOT; i++) begin
        valid[i] <= 1'b0;
        dirty[i] <= 1'b0;
      end
    end else if (wr_en) begin
      // CPU is writing
      data[index]  <= wdata;
      tag[index]   <= addr_tag;
      valid[index] <= 1'b1;
      dirty[index] <= 1'b1;
    end else if (rd_en && miss) begin
      // CPU is reading but addr doesn't exist
      // later do memory fetch instead
      valid[index] <= 1'b0; // slot is being replaced
      dirty[index] <= 1'b0; // fresh data from memory is clean
    end
  
  end
  
endmodule