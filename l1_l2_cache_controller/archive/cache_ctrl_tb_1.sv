`include "uvm_macros.svh"
`include "cc_uvm_pkg.sv"

import uvm_pkg::*;
import cc_uvm_pkg::*;

module tb;
  // IF
  cache_ctrl_if cc_if();
  
  //DUT
  cache_ctrl dut(.clk(cc_if.clk),
                 .rst(cc_if.rst),
                 .addr(cc_if.addr),
                 .wr_en(cc_if.wr_en),
                 .rd_en(cc_if.rd_en),
                 .wdata(cc_if.wdata),
                 .rdata(cc_if.rdata),
                 .hit(cc_if.hit),
                 .miss(cc_if.miss));
                 
   // Clock generator
   initial begin
     cc_if.clk <= 1'b0;
   end
   
   always begin
     #10ns cc_if.clk <= ~cc_if.clk; 
   end
                 
   // Reset
   initial begin
     cc_if.rst   <= 1'b1;
     
     cc_if.addr  <= 0;
     cc_if.wr_en <= 0;
     cc_if.rd_en <= 0;
     cc_if.wdata <= 0;
     
     repeat (5) @(posedge cc_if.clk);
     cc_if.rst <= 1'b0;
   end
   
  logic [`DATA_WIDTH-1:0] exp_data;
   // Simple write and read
   initial begin
     
     
     #205;
     // Read before write on unused cache slot
     // Should return miss
     @(posedge cc_if.clk);
     cc_if.rd_en <= 1'b1;
     cc_if.addr  <= 8'h4C;
     
     @(posedge cc_if.clk);
     cc_if.rd_en <= 1'b0;
     assert (cc_if.miss === 1'b1) begin
       `uvm_info("INFO", "Read returned a miss as expected on a cold read", UVM_NONE);
     end else begin
       `uvm_error("ERROR", "Read returned a hit instead of a miss on cold read");
     end
     
     // Start write
     exp_data = $urandom;
     
     @(posedge cc_if.clk);
     cc_if.wr_en <= 1'b1;
     cc_if.wdata <= exp_data;
     cc_if.addr  <= 8'h4C;
     #1 `uvm_info("INFO", $sformatf("wr_en: %0d, addr: %0h, wdata: %0h", cc_if.wr_en, cc_if.addr, cc_if.wdata), UVM_NONE);
     
     @(posedge cc_if.clk);
     
     // Check that write is successful by reading again
     cc_if.wr_en <= 1'b0;
     cc_if.rd_en <= 1'b1;
     cc_if.addr  <= 8'h4C;
     
     @(posedge cc_if.clk);
     cc_if.rd_en <= 1'b0;
     
     #205;
     $finish;
   end
  
   always begin
     @(posedge cc_if.clk);
     if (cc_if.rd_en === 1'b1 && cc_if.hit === 1'b1) begin
       assert(cc_if.rdata === exp_data) begin
         `uvm_info("INFO", $sformatf("rd_en: %0d, hit: %0d, addr: %0h, rdata: %0h", cc_if.rd_en, cc_if.hit, cc_if.addr, cc_if.rdata), UVM_NONE);
       end else begin
         `uvm_error("ERROR", "Read data incorrect");
       end
     end
   end
                 
   // Waveform
   initial begin
     $dumpfile("waveform.vcd");
     $dumpvars;
   end
                 
                 
endmodule