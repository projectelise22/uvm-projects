`ifndef CC_TYPES_SV
  `define CC_TYPES_SV

  // Virtual interface
  typedef virtual cache_ctrl_if cc_vif;

  // Transaction Items
  typedef enum bit { CC_WRITE, CC_READ } cc_op;

  typedef logic[`ADDR_WIDTH-1:0] cc_addr;

  typedef logic[`DATA_WIDTH-1:0] cc_data;

  // Cache model
  typedef struct {
    logic valid;
    logic [`TAG_WIDTH-1:0] tag;
    logic [`DATA_WIDTH-1:0] data;
  } cache_line_t;

`endif