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
  
  // Reset DUT
  initial begin
    cc_if.rst   <= 1'b1;
    cc_if.wr_en <= 1'b0;
    cc_if.rd_en <= 1'b0;
    cc_if.addr  <= 1'b0;
    cc_if.wdata <= 1'b0;
    
    repeat(5) @(posedge cc_if.clk);
    cc_if.rst <= 1'b0;
  end
  
   // Run test
   initial begin
     uvm_config_db#(cc_vif)::set(null, "*", "vif", cc_if);
     run_test("cc_base_test");
   end
    
   // Waveform
   initial begin
     $dumpfile("waveform.vcd");
     $dumpvars;
   end
                 
                 
endmodule