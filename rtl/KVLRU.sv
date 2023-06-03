module KVLRU #(
  parameter WAY_NUM     = 4,
  parameter LINE_NUM    = 64,
  localparam INDEX_WIDTH = $clog2(LINE_NUM / WAY_NUM),
  localparam LINE_NUM_PER_WAY   = LINE_NUM / WAY_NUM
)(
  input  logic  i_clk,
  input  logic  i_rstn,
  input  logic  [WAY_NUM-1:0]       i_hitway,
  input  logic  [INDEX_WIDTH-1:0]   i_index,
  output logic  [WAY_NUM-1:0]       o_killmask
);

  logic [1:0] debug_bit2index;
  logic [1:0] debug_lru_array[3:0];

  logic [WAY_NUM-1:0] w_killmask;
  logic [WAY_NUM-1:0] r_killmask;
  logic [WAY_NUM-1:0] w_uso_killmask;
  logic [WAY_NUM-1:0] r_uso_killmask;

  logic [1:0] w_lru_array[3:0];
  logic [1:0] r_lru_array[LINE_NUM_PER_WAY-1:0][3:0];

  logic w_miss;
  logic [WAY_NUM-1:0] w_all_zero_check;
  logic w_all_zero;

  function [$clog2(WAY_NUM)-1:0] bit2index(input [WAY_NUM-1:0] bits);
    bit [$clog2(WAY_NUM):0] way;
    for(way = 0; way < ($clog2(WAY_NUM)+1)'(WAY_NUM); way = way + 1) begin : BIT_TO_INDEX
      if(bits[way[$clog2(WAY_NUM)-1:0]]) begin
        return way[$clog2(WAY_NUM)-1:0];
      end
    end
    return ($clog2(WAY_NUM))'(WAY_NUM-1);
  endfunction

  generate for(genvar way = 0; way < WAY_NUM; way = way + 1) begin
    always_comb begin
      w_uso_killmask[way]   = (r_lru_array[i_index][way] == '1);
    end
  end endgenerate

  always_ff @(posedge i_clk) begin
    r_uso_killmask  <= w_uso_killmask;
  end

  generate for(genvar way = 0; way < WAY_NUM; way = way + 1) begin
    always_comb begin
      if(r_lru_array[i_index][way] == '0) begin
        w_all_zero_check[way]   = 1'b1;
      end else begin
        w_all_zero_check[way]   = 1'b0;
      end
    end
  end endgenerate

  always_comb begin
    w_miss      = ~|i_hitway;
    w_all_zero  = &w_all_zero_check;
  end

  generate for(genvar way = 0; way < WAY_NUM; way = way + 1) begin
    always_comb begin
      if(~|w_uso_killmask) begin    // all uso killmask is zero
        if(way == 0) begin
          if(w_all_zero) begin
            w_killmask[way]   = 1'b1;
            w_lru_array[way]    = 0;
          end else begin
            w_killmask[way]   = 1'b0;
            w_lru_array[way]    = r_lru_array[i_index][way] + 1;
          end
        end else begin
          if(w_all_zero) begin
            w_killmask[way]   = 1'b0;
            w_lru_array[way]    = 1;
          end else begin
            if(r_lru_array[i_index][way-1] == '0) begin
              w_killmask[way]   = 1'b1;
              w_lru_array[way]  = '0;
            end else begin
              w_killmask[way]   = 1'b0;
              w_lru_array[way]  = r_lru_array[i_index][way] + 1;
            end
          end
        end
      end else begin
        w_killmask[way] = (r_lru_array[i_index][way] == '1);
        if(w_miss) begin
          if(bit2index(w_killmask) == way) begin
            w_lru_array[way]  = '0;
          end else begin
            w_lru_array[way]  = r_lru_array[i_index][way] + 1;
          end
        end else begin
          if(i_hitway[way]) begin
            w_lru_array[way]  = '0;
          end else begin
            if(r_lru_array[i_index][way] < r_lru_array[i_index][bit2index(i_hitway)]) begin
              w_lru_array[way]    = r_lru_array[i_index][way] + 1;
            end else begin
              w_lru_array[way]    = r_lru_array[i_index][way];
            end
          end
        end
      end
    end
  end endgenerate

  always_ff @(posedge i_clk) begin
    r_lru_array[i_index]    <= w_lru_array;
    r_killmask              <= w_killmask;
  end

  always_comb begin
    o_killmask  = w_killmask;
    debug_lru_array = r_lru_array[i_index];
  end

endmodule
