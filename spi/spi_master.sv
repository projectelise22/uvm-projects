module spi_master(
    input clk, rst, newd,
    input logic[11:0] din,
    output reg cs, mosi, sclk
);

typedef enum bit[1:0] {
    IDLE   = 2'b00,
    ENABLE = 2'b01,
    SEND   = 2'b10,
    COMP   = 2'b11
} state_type;
state_type state = IDLE;

int count_clk;
int count;
reg [11:0] temp;

// sclk generation
always @(posedge clk) begin
    if (rst) begin
        count_clk <= 0;
        sclk      <= 1'b0;
    end else begin
        if (count_clk < 10)
          count_clk <= count_clk + 1;
        else begin
            count_clk <= 1'b0;
            sclk      <= ~sclk;
        end
    end
end

// state machine
always @(posedge sclk) begin
    if (rst) begin
        cs   <= 1'b1; // active low slave enable
        mosi <= 1'b0;
    end else begin
        case (state)
          IDLE: if (newd) begin
                  cs    <= 1'b0;
                  mosi  <= 1'b0;
                  temp  <= din;
                  state <= SEND;
                end else begin
                  cs    <= 1'b1;
                  mosi  <= 1'b0;
                  temp  <= 8'h00;
                  state <= IDLE;
                end
          SEND: if (count <= 11) begin
                  cs    <= 1'b0;
                  mosi  <= temp[count];
                  count++;
                  state <= SEND;
                end else begin
                  cs    <= 1'b1;
                  mosi  <= 1'b0;
                  count <= 0;
                  state <= IDLE;  
                end
          default: state <= IDLE;
        endcase
    end
end
endmodule

interface spi_if;
  logic clk;
  logic rst;
  logic newd;
  logic [11:0] din;
  logic sclk;
  logic cs;
  logic mosi;
  logic [11:0] dout;
  logic done;

  clocking cb_drv @(posedge sclk);
    output newd, din;
    input cs, mosi;
  endclocking

  clocking cb_mon @(posedge sclk);
    input newd, din, cs, mosi;
  endclocking

  modport drv (clocking cb_drv, input clk, rst);
  modport mon (clocking cb_mon, input clk, rst);
endinterface