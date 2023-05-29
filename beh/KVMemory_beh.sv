// Behavioral Memory
module KVMemory_beh #(
  parameter DATA_WIDTH  = 32,
  parameter ADDR_WIDTH  = 32,
  parameter LINE_SIZE   = 4
)(
  input  logic  i_clk,
  input  logic  i_rstn,
  // Read Signal
  // Addr
  input  logic  [ADDR_WIDTH-1:0]    i_read_addr,
  input  logic                      i_read_valid,
  output logic                      o_read_ready,
  // Data
  output logic  [DATA_WIDTH-1:0]    o_read_data[LINE_SIZE-1:0],
  output logic                      o_read_valid,
  input  logic                      i_read_ready
);

  logic [DATA_WIDTH-1:0]    r_mem[LINE_SIZE*2-1:0] = '{32'h0000_0000, 32'h0000_5555, 32'h5555_0000, 32'h5555_5555, 32'h9999_9999, 32'h9999_0000, 32'h0000_9999, 32'h8888_8888};

  logic [DATA_WIDTH-1:0]    w_o_read_data[LINE_SIZE-1:0];
  logic                     w_o_read_valid;

  logic [ADDR_WIDTH-1:0] w_shift_addr[3:0];
  logic [ADDR_WIDTH-1:0] r_shift_addr[3:0];

  logic [3:0] w_shift_reg;
  logic [3:0] r_shift_reg = 4'b0000;

  logic [2:0] w_cnt;
  logic [2:0] r_cnt = '0;

  // Read
  always_comb begin
    if(~i_read_valid) begin
      o_read_ready = i_read_ready;
    end else if(r_cnt == 3'b100) begin
      o_read_ready = i_read_ready;
    end else begin
      o_read_ready  = i_read_ready & o_read_valid;
    end
    if((r_cnt == 3'b011)) begin
      w_o_read_valid    = i_read_valid;
      w_o_read_data[0]  = r_mem[{i_read_addr[2], 2'b00}];
      w_o_read_data[1]  = r_mem[{i_read_addr[2], 2'b01}];
      w_o_read_data[2]  = r_mem[{i_read_addr[2], 2'b10}];
      w_o_read_data[3]  = r_mem[{i_read_addr[2], 2'b11}];
    end else begin
      w_o_read_valid    = 1'b0;
      w_o_read_data[0]  = o_read_data[0];
      w_o_read_data[1]  = o_read_data[1];
      w_o_read_data[2]  = o_read_data[2];
      w_o_read_data[3]  = o_read_data[3];
    end
    if(i_read_ready) begin
      if(i_read_valid) begin
        if(r_cnt == 3'b100) begin
          w_cnt = '0;
        end else begin
          w_cnt = r_cnt + 3'b001;
        end
      end else begin
        w_cnt = '0;
      end
    end else begin
      w_cnt = r_cnt;
    end
  end

  always_ff @(posedge i_clk) begin
    o_read_data[0]  <= w_o_read_data[0];
    o_read_data[1]  <= w_o_read_data[1];
    o_read_data[2]  <= w_o_read_data[2];
    o_read_data[3]  <= w_o_read_data[3];
    o_read_valid    <=  w_o_read_valid;
    r_cnt           <=  w_cnt;
  end

  /*
  always_comb begin
    o_read_valid = r_shift_reg[3];
    if(~r_shift_reg[3] || i_read_ready) begin
      w_o_read_data[0]  = r_mem[{r_shift_addr[3][2], 2'b00}];
      w_o_read_data[1]  = r_mem[{r_shift_addr[3][2], 2'b01}];
      w_o_read_data[2]  = r_mem[{r_shift_addr[3][2], 2'b10}];
      w_o_read_data[3]  = r_mem[{r_shift_addr[3][2], 2'b11}];
    end else begin
      w_o_read_data[0]  = o_read_data[0];
      w_o_read_data[1]  = o_read_data[1];
      w_o_read_data[2]  = o_read_data[2];
      w_o_read_data[3]  = o_read_data[3];
    end
    o_read_ready = ~|r_shift_reg | (r_shift_reg[3] & i_read_ready);
    if(|r_shift_reg[2:0]) begin
      w_shift_reg = {r_shift_reg[2:0], 1'b0};
    end else begin
      w_shift_reg = {r_shift_reg[2:0], i_read_valid};
    end
    w_shift_addr = {r_shift_addr[2], r_shift_addr[1], r_shift_addr[0], i_read_addr};
  end

  always_ff @(posedge i_clk) begin
    r_shift_reg     <= w_shift_reg;
    r_shift_addr    <= w_shift_addr;
    o_read_data[0]  <= w_o_read_data[0];
    o_read_data[1]  <= w_o_read_data[1];
    o_read_data[2]  <= w_o_read_data[2];
    o_read_data[3]  <= w_o_read_data[3];
  end
  */

endmodule
