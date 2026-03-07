module fifo (
    input clk, rst, wr_en, rd_en,
    input [7:0] data_in,
    output full, empty,
    output reg [7:0] data_out 
);

reg [3:0] wr_ptr, rd_ptr;
reg [4:0] cnt = 0;
reg [7:0] mem [15:0];

always @(posedge clk) begin
    if (rst) begin
       wr_ptr <= 0;
       rd_ptr <= 0;
       cnt <= 0;
    end
    else if (wr_en && !full) begin
        mem[wr_ptr] <= data_in;
        wr_ptr <= wr_ptr + 1;
        cnt <= cnt + 1; 
    end 
    else if (rd_en && !empty) begin
        data_out <= mem[rd_ptr];
        rd_ptr <= rd_ptr + 1;
        cnt <= cnt - 1;
    end
end

assign empty = (cnt == 0) ? 1'b1 : 1'b0;
assign full = (cnt == 16) ? 1'b1 : 1'b0;

endmodule

interface fifo_if;
  logic clk;
  logic rst;
  logic wr_en;
  logic rd_en;
  logic [7:0] data_in;
  logic [7:0] data_out;
  logic full;
  logic empty;
endinterface