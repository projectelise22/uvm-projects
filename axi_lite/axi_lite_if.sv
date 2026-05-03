`ifndef AXI_LITE_IF_SV
  `define AXI_LITE_IF_SV

  `ifndef ADDR_WIDTH
    `define ADDR_WIDTH 8
  `endif

  `ifndef DATA_WIDTH
    `define DATA_WIDTH 32
  `endif

interface axi_lite_if();
  
  logic clk;
  logic rst;
  
  // Write Address Channel
  logic                   awvalid;
  logic                   awready;
  logic [`ADDR_WIDTH-1:0] awaddr;
  
  // Write Data Channel
  logic                   wvalid;
  logic                   wready;
  logic [`DATA_WIDTH-1:0] wdata;
  
  // Write Response Channel
  logic                   bvalid;
  logic                   bready;
  logic                   [1:0] bresp;
  
  // Read Address Channel
  logic                   arvalid;
  logic                   arready;
  logic [`ADDR_WIDTH-1:0] araddr;
  
  // Read Response Channel
  logic                   rvalid;
  logic                   rready;
  logic [1:0]             rresp;
  logic [`DATA_WIDTH-1:0] rdata;
  
endinterface
`endif