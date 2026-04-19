`include "uvm_macros.svh"
import uvm_pkg::*;

/* Random Packet Generator
Create a transaction class representing a packet:
    addr (8 bits)
    data (32 bits)
    length (1–16)
    write/read flag
Requirements:
- addr must be aligned to 4 bytes
- length between 1 and 16
- if write == 0, data should be 0

Tasks:
- randomize packets
- print them
- generate 10 packets
*/
class transaction extends uvm_sequence_item;
  rand logic [7:0] addr;
  rand logic [31:0] data;
  rand int length;
  rand logic wr;

  constraint c_addr {
    addr[1:0] == 2'b00;
    addr dist { [8'h00:8'h1F] := 25,
                [8'h20:8'h3F] := 25,
                [8'h40:8'h7F] := 50,
                [8'h80:8'hFF] := 0 };
  }

  constraint c_length {
    length inside {[1:16]};
  }

  constraint c_write {
    wr == 0 -> data == 32'h0000; 
    wr dist { 0 := 7, 1 := 3 };
  }

  function new(string inst="transaction");
    super.new(inst);
  endfunction

  `uvm_object_utils_begin(transaction)
    `uvm_field_int(addr, UVM_HEX);
    `uvm_field_int(data, UVM_HEX);
    `uvm_field_int(length, UVM_DEFAULT);
    `uvm_field_int(wr, UVM_DEFAULT);
  `uvm_object_utils_end
endclass

class test extends uvm_test;
  `uvm_component_utils(test);

  transaction tx;
  my_coverage cov;

  function new(string path="test", uvm_component parent=null);
    super.new(path, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cov = my_coverage::type_id::create("cov");
    cov.cg = my_coverage::covergroup::type_id::create("cg");
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    repeat (10) begin
      tx = transaction::type_id::create("tx");
      tx.randomize();
      tx.print();
      cov.cg.addr = tx.addr;
      cov.cg.sample();
      #10;
    end
    phase.drop_objection(this);
  endtask
endclass

class my_coverage extends uvm_object;
  `uvm_object_utils(my_coverage);

  function new(string inst="my_coverage");
    super.new(inst);
  endfunction

  covergroup cg;
    coverpoint addr {
        bins control  = {[8'h00:8'h1F]};
        bins status   = {[8'h20:8'h3F]};
        bins memory   = {[8'h40:8'h7F]};
        bins reserved = {[8'h80:8'hFF]}; 
    }
  endcovergroup
endclass

module tb;
  initial run_test("test");
endmodule