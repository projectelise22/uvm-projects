module sfifo #(parameter DEPTH=8, DWIDTH=16)
(
        input               	rstn,               // Active low reset
                            	clk,                // Clock
                            	wr_en, 				// Write enable
                            	rd_en, 				// Read enable
        input      [DWIDTH-1:0] din, 				// Data written into FIFO
        output reg [DWIDTH-1:0] dout, 				// Data read from FIFO
        output              	empty, 				// FIFO is empty when high
                            	full 				// FIFO is full when high
);


  reg [$clog2(DEPTH)-1:0]   wptr;
  reg [$clog2(DEPTH)-1:0]   rptr;

  reg [DWIDTH-1 : 0]    fifo[DEPTH];

  always @ (posedge clk) begin
    if (!rstn) begin
      wptr <= 0;
    end else begin
      if (wr_en & !full) begin
        fifo[wptr] <= din;
        wptr <= wptr + 1;
      end
    end
  end

  initial begin
    $monitor("[%0t] [FIFO] wr_en=%0b din=0x%0h rd_en=%0b dout=0x%0h empty=%0b full=%0b",
             $time, wr_en, din, rd_en, dout, empty, full);
  end

  always @ (posedge clk) begin
    if (!rstn) begin
      rptr <= 0;
    end else begin
      if (rd_en & !empty) begin
        dout <= fifo[rptr];
        rptr <= rptr + 1;
      end
    end
  end

  assign full  = (wptr + 1) == rptr;
  assign empty = wptr == rptr;
endmodule

interface sfifo_if#(parameter DWIDTH=16);
  logic rstn;
  logic clk;
  logic wr_en;
  logic rd_en;
  logic [DWIDTH-1:0] din;
  logic [DWIDTH-1:0] dout;
  logic empty;
  logic full;

  // DRIVER clocking block
  clocking drv_cb @(posedge clk);
    output wr_en, rd_en, din;
    input  dout, empty, full;
  endclocking

  // MONITOR clocking block
  clocking mon_cb @(posedge clk);
    input wr_en, rd_en, din;
    input dout, empty, full;
  endclocking

  modport drv (clocking drv_cb, input rstn);
  modport mon (clocking mon_cb, input rstn);

endinterface