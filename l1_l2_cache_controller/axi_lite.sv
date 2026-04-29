module axi_lite #(parameter int ADDR_WIDTH = 8,
                  parameter int DATA_WIDTH = 32) (
  input logic clk,
  input logic rst,
  
  // Write Address Channel
  input logic [ADDR_WIDTH-1:0]  awaddr,
  input logic                   awvalid,
  output logic                  awready,
  
  // Write Data Channel
  input logic [DATA_WIDTH-1:0]  wdata,
  input logic                   wvalid,
  output logic                  wready,
  
  // Write Response Channel
  output logic [1:0]            bresp,
  output logic                  bvalid,
  input logic                   bready,
  
  // Read Address Channel
  input logic [ADDR_WIDTH-1:0]  araddr,
  input logic                   arvalid,
  output logic                  arready,
  
  // Read Response Channel
  output logic [DATA_WIDTH-1:0] rdata,
  output logic [1:0]            rresp,
  output logic                  rvalid,
  input logic                   rready
);
  
  // --------------- //
  // Parameters
  // --------------- //
  localparam int CACHE_SLOT = 4;
  localparam int TAG_WIDTH  = ADDR_WIDTH - $clog2(CACHE_SLOT);
  
  typedef enum bit[2:0] {
    IDLE       = 3'b000,
    DO_WRITE   = 3'b001,
    SEND_BRESP = 3'b010,
    DO_READ    = 3'b101,
    SEND_RDATA = 3'b110
  } axi_state_t;
  
  // --------------- //
  // AXI Registers
  // --------------- //
  axi_state_t state, next_state;
  logic [ADDR_WIDTH-1:0] awaddr_reg;
  logic [DATA_WIDTH-1:0] wdata_reg;
  logic [ADDR_WIDTH-1:0] araddr_reg;
  
  logic awdone;
  logic wdone;
  
  // ------------------- //
  // Cache memory array
  // ------------------- //
  logic                  valid [CACHE_SLOT];
  logic                  dirty [CACHE_SLOT];
  logic [TAG_WIDTH-1:0]  tag   [CACHE_SLOT];
  logic [DATA_WIDTH-1:0] data  [CACHE_SLOT];

  logic [$clog2(CACHE_SLOT)-1:0] aw_index;
  logic [TAG_WIDTH-1:0]          aw_tag;
  
  logic [$clog2(CACHE_SLOT)-1:0] ar_index;
  logic [TAG_WIDTH-1:0]          ar_tag;
  
  logic hit;
  
  // --------------------------------------------------------------- //
  // AXI handshake logic
  // Transfer only happens when valid and ready are both asserted
  // --------------------------------------------------------------- //
  logic aw_hs, w_hs, ar_hs;
  
  assign aw_hs = awvalid && awready;
  assign w_hs  = wvalid && wready;
  assign ar_hs = arvalid && arready;
  
  // capture write address and data
  always_ff @(posedge clk) begin
    if (rst) begin
      awdone <= 0;
      wdone  <= 0;
    end else begin
      if (aw_hs) begin
        awaddr_reg <= awaddr;
        awdone <= 1;
      end
      
      if (w_hs) begin
        wdata_reg <= wdata;
        wdone     <= 1;
      end
      
      // clear after write completes
      if (state == SEND_BRESP && bready && bvalid) begin
        awdone <= 0;
        wdone  <= 0;
      end
    end
  end
  
  // capture read address
  always_ff @(posedge clk) begin
    if (rst) begin
      araddr_reg <= 0;
    end else if (ar_hs) begin
      araddr_reg <= araddr;
    end
  end
  
  // current state logic
  always_ff @(posedge clk) begin
    if (rst) begin
      state <= IDLE;
    end else begin
      state <= next_state;
    end
  end
  
  // next state logic
  always_comb begin
    case (state)
      IDLE: begin
        if (awdone && wdone) begin
          next_state = DO_WRITE;        // write takes priority
        end else if (ar_hs) begin
          next_state = DO_READ;         // read only if no write pending
        end else begin
          next_state = IDLE;
        end
      end
      DO_WRITE: begin
        next_state = SEND_BRESP;
      end
      SEND_BRESP: begin
        if (bready === 1'b1) begin
          next_state = IDLE;
        end else begin
          next_state = SEND_BRESP;
        end
      end
      DO_READ: begin
        next_state = SEND_RDATA;
      end
      SEND_RDATA: begin
        if (rready === 1'b1) begin
          next_state = IDLE;
        end else begin
          next_state = SEND_RDATA;
        end
      end
      default: next_state = IDLE;
    endcase
  end

  // --------------------------- //
  // Cache address split logic
  // --------------------------- //
  assign aw_index = awaddr_reg[$clog2(CACHE_SLOT)-1:0];
  assign aw_tag   = awaddr_reg[ADDR_WIDTH-1:$clog2(CACHE_SLOT)];

  assign ar_index = araddr_reg[$clog2(CACHE_SLOT)-1:0];
  assign ar_tag   = araddr_reg[ADDR_WIDTH-1:$clog2(CACHE_SLOT)];

  assign hit      = valid[ar_index] && (tag[ar_index] == ar_tag);

  // cache memory operation
  always_ff @(posedge clk) begin
    if (rst) begin
        valid[aw_index] <= 1'b0;
        dirty[aw_index] <= 1'b0;
    end else begin
        
        // write operation
        if (state == DO_WRITE) begin
          data[aw_index]  <= wdata_reg;
          tag[aw_index]   <= aw_tag;
          valid[aw_index] <= 1'b1;
          dirty[aw_index] <= 1'b1;
        end
    end
    end
    end
  end
  
  // output ready signals
  assign awready = (state == IDLE) && !awdone;
  assign wready  = (state == IDLE) && !wdone;
  assign arready = (state == IDLE) && !awdone && !wdone;
  
  // output logic
  always_ff @(posedge clk) begin
    if (rst) begin
      bvalid <= 0;
      rvalid <= 0;
    end else begin

      // Write response
      if (state == DO_WRITE)
        bvalid <= 1;
      else if (bvalid && bready)
        bvalid <= 0;

      // Read response
      if (state == DO_READ) begin
        rvalid <= 1;
        if (hit) begin
          rdata <= data[ar_index];
          rresp <= 2'b00; // response is OK
        end else begin
          rdata <= 0;
          rresp <= 2'b10; // response is SLVERR, miss
        end
      end
      else if (rvalid && rready)
        rvalid <= 0;

    end
  end

  assign bresp = 2'b00;

endmodule