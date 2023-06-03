module KVLRU #(
  parameter WAY_NUM     = 4,
  parameter LINE_NUM    = 64,
  localparam INDEX_WIDTH = $clog2(LINE_NUM / WAY_NUM),
  localparam LINE_NUM_PER_WAY   = LINE_NUM / WAY_NUM
)(
  input  logic  i_clk,
  input  logic  i_rstn,
  input  logic  [WAY_NUM-1:0]       i_valid_way,
  input  logic  [WAY_NUM-1:0]       i_hitway,
  input  logic  [INDEX_WIDTH-1:0]   i_index,
  output logic  [WAY_NUM-1:0]       o_killmask
);

  logic [WAY_NUM-1:0] w_killmask;

  logic [1:0] w_lru_array[3:0];
  logic [1:0] r_lru_array[3:0][LINE_NUM_PER_WAY-1:0];

  function [$clog2(WAY_NUM)-1:0] bit2index(input [WAY_NUM-1:0] bits);
    bit [$clog2(WAY_NUM):0] way;
    for(way = 0; way < ($clog2(WAY_NUM)+1)'(WAY_NUM); way = way + 1) begin : BIT_TO_INDEX
      if(bits[way[$clog2(WAY_NUM)-1:0]]) begin
        return way[$clog2(WAY_NUM)-1:0];
      end
    end
    return ($clog2(WAY_NUM))'(WAY_NUM-1);
  endfunction

  always_comb begin
    if(i_hitway = 4'b0000) begin
      w_killmask = 4'b0001;
    end else begin

    end
  end

  generate
    for(genvar way = 0; way < WAY_NUM; way = way + 1) begin
      always_comb begin
        if(r_lru_array[i_index][way] == 2'b11) begin
          w_killmask[way]   = 1'b1;
        end else begin
          w_killmask[way]   = 1'b0;
        end
      end
    end
  endgenerate

  generate
    for(genvar way = 0; way < WAY_NUM; way = way + 1) begin
      always_comb begin
        if(i_hitway == 4'b0000) begin
        end else begin
          if(i_hitway[way]) begin
            w_lru_array[way] = 2'b00;
          end else begin
            w_lru_array[way] = r_lru_array[i_index][way] + 2'b01;
          end
        end
      end
    end
  endgenerate

  always_ff @(posedge i_clk) begin
    r_lru_array[i_index]    <= w_lru_array;
    o_killmask              <= w_killmask;
  end


endmodule
