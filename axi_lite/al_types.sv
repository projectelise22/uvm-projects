`ifndef AL_TYPES_SV
  `define AL_TYPES_SV

  // Virtual Interface
  virtual axi_lite_if axi_lite_vif;

  // Transaction items
  typedef enum bit { AXI_WRITE = 1'b0 , AXI_READ = 1'b1} axi_op_t;

  typedef enum bit[1:0] { AW_FIRST, W_FIRST, SIMULTANEOUS } aw_w_order_t;

  typedef logic [`ADDR_WIDTH-1:0] axi_addr;

  typedef logic [`DATA_WIDTH-1:0] axi_data;

  typedef logic [1:0] axi_resp;  
`endif