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
  logic [WAY_NUM-2:0] w_lru_array_row;
  logic [WAY_NUM-1:0] w_lru_array[WAY_NUM-1:0];
  logic [WAY_NUM-1:0] r_lru_array[LINE_NUM_PER_WAY-1:0][WAY_NUM-1:0];

  function [$clog2(WAY_NUM)-1:0] bit2index(input [WAY_NUM-1:0] bits);
    bit [$clog2(WAY_NUM):0] way;
    for(way = 0; way < ($clog2(WAY_NUM)+1)'(WAY_NUM); way = way + 1) begin : BIT_TO_INDEX
      if(bits[way[$clog2(WAY_NUM)-1:0]]) begin
        return way[$clog2(WAY_NUM)-1:0];
      end
    end
    return ($clog2(WAY_NUM))'(WAY_NUM-1);
  endfunction

  generate
    for(genvar way = 0; way < WAY_NUM; way = way + 1) begin : UPDATE_LRU_ARRAY0
      always_comb begin
        if(bit2index(i_hitway) == way) begin
          w_lru_array[bit2index(i_hitway)] = '0;
        end else begin
          w_lru_array[way][bit2index(i_hitway)] = 1'b1;
        end
      end
    end
  endgenerate

  generate
    for(genvar way = 0; way < WAY_NUM; way = way + 1) begin : UPDATE_LRU_ARRAY1
      always_ff @(posedge i_clk) begin
        if(bit2index(i_hitway) == way) begin
          r_lru_array[i_index][bit2index(i_hitway)] = w_lru_array[bit2index(i_hitway)];
        end else begin
          r_lru_array[i_index][way][bit2index(i_hitway)] = w_lru_array[way][bit2index(i_hitway)];
        end
      end
    end
  endgenerate

  generate
    for(genvar way = 0; way < WAY_NUM-1; way = way + 1) begin : SELECT_OLD_WAY
      always_comb begin
        w_lru_array_row[way] = &r_lru_array[i_index][way][WAY_NUM-1:way+1];
      end
    end
  endgenerate
  
  always_comb begin
    if(|w_lru_array_row) begin
      w_killmask  = {1'b0, w_lru_array_row};
    end else begin
      w_killmask  = {1'b1, w_lru_array_row};
    end
  end

  always_ff @(posedge i_clk) begin
  end

endmodule
