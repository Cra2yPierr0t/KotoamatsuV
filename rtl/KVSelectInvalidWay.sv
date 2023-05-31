module KVSelectInvalidWay #(
  parameter WAY_NUM = 4
)(
  input     logic [WAY_NUM-1:0] i_valid_way,
  output    logic [WAY_NUM-1:0] o_killmask
);

  generate
    for(genvar way = 0; way < WAY_NUM; way = way + 1) begin
      if(way == 0) begin
        always_comb begin
          o_killmask[way]   = ~i_valid_way[way];
        end
      end else begin
        always_comb begin
          o_killmask[way]   = ~i_valid_way[way] & (&i_valid_way[way-1:0]);
        end
      end
    end
  endgenerate

endmodule
