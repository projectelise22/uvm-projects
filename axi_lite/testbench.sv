`include "uvm_macros.svh"
`include "al_uvm_pkg.sv"

import uvm_pkg::*;
import al_uvm_pkg::*;

module tb;
  // Interface
  axi_lite_if al_if();
  
  // DUT
  axi_lite al_cache(.clk(al_if.clk),
                    .rst(al_if.rst),
                    
                    .awvalid(al_if.awvalid),
                    .awready(al_if.awready),
                    .awaddr(al_if.awaddr),
                    
                    .wvalid(al_if.wvalid),
                    .wready(al_if.wready),
                    .wdata(al_if.wdata),
                    
                    .bvalid(al_if.bvalid),
                    .bready(al_if.bready),
                    .bresp(al_if.bresp),
                    
                    .arvalid(al_if.arvalid),
                    .arready(al_if.arready),
                    .araddr(al_if.araddr),
                    
                    .rvalid(al_if.rvalid),
                    .rready(al_if.rready),
                    .rresp(al_if.rresp),
                    .rdata(al_if.rdata));
endmodule