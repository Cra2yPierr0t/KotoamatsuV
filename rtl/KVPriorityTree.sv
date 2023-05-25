module KVPriorityTree #(
  parameter DATA_WIDTH  = 32,
  parameter DATA_NUM    = 2
)(
  input  logic [DATA_WIDTH-1:0] i_datas[DATA_NUM-1:0],
  input  logic [DATA_NUM-1:0]   i_valid,
  output logic [DATA_WIDTH-1:0] o_data
);

  /* verilator lint_off UNOPTFLAT */
  logic [DATA_WIDTH-1:0] w_internal[DATA_NUM-1:0];
  /* verilator lint_on UNOPTFLAT */

  assign o_data = w_internal[0];
  assign w_internal[DATA_NUM-1] = i_datas[DATA_NUM-1];
  generate
    for(genvar i = 0; i < DATA_NUM-1; i = i + 1) begin : GEN_TREE
      assign w_internal[i] = i_valid[i] ? i_datas[i] : w_internal[i+1];
    end
  endgenerate

endmodule
