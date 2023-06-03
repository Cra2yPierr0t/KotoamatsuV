module KVCache #(
  parameter DATA_WIDTH  = 32,
  parameter ADDR_WIDTH  = 32,
  parameter WAY_NUM     = 4,
  parameter LINE_SIZE   = 4,
  parameter LINE_NUM    = 64,
  localparam LINEOFFSET_WIDTH = $clog2(LINE_SIZE),
  localparam INDEX_WIDTH = $clog2(LINE_NUM / WAY_NUM),
  localparam TAG_WIDTH = ADDR_WIDTH - (INDEX_WIDTH + LINEOFFSET_WIDTH),
  localparam LINE_WIDTH = DATA_WIDTH * LINE_SIZE,
  localparam LINE_NUM_PER_WAY = LINE_NUM / WAY_NUM
)(
  input  logic i_clk,
  input  logic i_rstn,
  // Processor Signal
  // Load
  output logic [DATA_WIDTH-1:0] o_load_data,
  output logic                  o_load_valid,
  input  logic                  i_load_ready,
  input  logic [ADDR_WIDTH-1:0] i_load_addr,
  input  logic                  i_load_valid,
  output logic                  o_load_ready,
  // Store
  input  logic [DATA_WIDTH-1:0] i_store_data,
  input  logic [ADDR_WIDTH-1:0] i_store_addr,
  input  logic                  i_store_valid,
  output logic                  o_store_ready,

  // Memory Signal
  // Fetch
  input  logic [DATA_WIDTH-1:0] i_fetch_data[LINE_SIZE-1:0],
  input  logic                  i_fetch_valid,
  output logic                  o_fetch_ready,
  output logic [ADDR_WIDTH-1:0] o_fetch_addr,
  output logic                  o_fetch_valid,
  input  logic                  i_fetch_ready,
  // Write
  input  logic                  i_line_valid,
  output logic                  o_line_ready,
  input  logic [LINE_WIDTH-1:0] i_line_data,
  output logic [ADDR_WIDTH-1:0] o_line_addr,
  output logic [LINE_WIDTH-1:0] o_line_data
);

  logic                  w_o_fetch_ready;
  logic [ADDR_WIDTH-1:0] w_o_fetch_addr;
  logic                  w_o_fetch_valid;

  logic [DATA_WIDTH-1:0] w_rdata;
  logic [DATA_WIDTH-1:0] w_rdataway[WAY_NUM-1:0];
  logic [DATA_WIDTH-1:0] w_wdataway[WAY_NUM-1:0];
  logic [WAY_NUM-1:0] w_cachemissway;
  logic w_cachemiss;

  // Cache Register
  logic [WAY_NUM-1:0]           w_cache_valid;
  logic [TAG_WIDTH-1:0]         w_cache_tag[WAY_NUM];
  logic [DATA_WIDTH-1:0]        w_cache_line[WAY_NUM-1:0][LINE_SIZE-1:0];
  logic [LINE_NUM_PER_WAY-1:0]  r_cache_valid[WAY_NUM-1:0];
  logic [TAG_WIDTH-1:0]         r_cache_tag[WAY_NUM-1:0][LINE_NUM_PER_WAY-1:0];
  logic [DATA_WIDTH-1:0]        r_cache_line[WAY_NUM-1:0][LINE_NUM_PER_WAY-1:0][LINE_SIZE-1:0];

  // Killmask
  logic [WAY_NUM-1:0]           w_killmask;
  logic [WAY_NUM-1:0]           r_killmask = 1;

  logic [TAG_WIDTH-1:0]         w_tag;
  logic [INDEX_WIDTH-1:0]       w_index;
  logic [LINEOFFSET_WIDTH-1:0]  w_lineoffset;
  logic [TAG_WIDTH-1:0]         r_tag;
  logic [INDEX_WIDTH-1:0]       r_index;
  logic [LINEOFFSET_WIDTH-1:0]  r_lineoffset;

  logic [LINEOFFSET_WIDTH-1:0]  w_lineoffset_internal;
  logic [LINEOFFSET_WIDTH-1:0]  r_lineoffset_internal;
  logic                         w_miss_internal;
  logic                         r_miss_internal;

  // Signals for Hit Check Stage
  logic                         w_hitcheck_cke;
  logic                         w_hitcheck_valid;
  logic                         r_hitcheck_valid;
  logic                         w_hitcheck_ready;
  logic [WAY_NUM-1:0]           w_hitcheck_hitway;
  logic [WAY_NUM-1:0]           r_hitcheck_hitway;
  logic                         w_hitcheck_miss;
  logic                         r_hitcheck_miss;
  logic [TAG_WIDTH-1:0]         w_hitcheck_tag;
  logic [TAG_WIDTH-1:0]         r_hitcheck_tag;
  logic [INDEX_WIDTH-1:0]       w_hitcheck_index;
  logic [INDEX_WIDTH-1:0]       r_hitcheck_index;
  logic [LINEOFFSET_WIDTH-1:0]  w_hitcheck_lineoffset;
  logic [LINEOFFSET_WIDTH-1:0]  r_hitcheck_lineoffset;
  logic [ADDR_WIDTH-1:0]        w_hitcheck_addr;
  logic [ADDR_WIDTH-1:0]        r_hitcheck_addr;
  logic                         w_i_load_valid;
  logic                         r_i_load_valid;

  // Signals for Fetch Stage
  logic                         w_fetch_cke;
  logic                         w_fetch_valid;
  logic                         r_fetch_valid;
  logic [LINEOFFSET_WIDTH-1:0]  w_fetch_lineoffset;
  logic [LINEOFFSET_WIDTH-1:0]  r_fetch_lineoffset;
  logic [DATA_WIDTH-1:0]        w_load_data[LINE_SIZE-1:0];
  logic [DATA_WIDTH-1:0]        r_load_data[LINE_SIZE-1:0];

  // Signals for Load Stage
  logic                         w_load_cke;
  logic                         w_load_ready;
  logic                         w_o_load_valid;
  logic [DATA_WIDTH-1:0]        w_o_load_data;

  // Signals for Cache Algorithm
  logic [WAY_NUM-1:0]           w_valid_way;
  logic [WAY_NUM-1:0]           w_lru_killmask;
  logic [WAY_NUM-1:0]           w_invalid_killmask;


  // Hit Check Stage
  // Hit Check Logic
  generate 
    for(genvar way = 0; way < WAY_NUM; way = way + 1) begin : HIT_CHECK_LOGIC
      always_comb begin
        if(w_hitcheck_cke) begin
          w_hitcheck_hitway[way]    = r_cache_valid[way][w_hitcheck_index] & (r_cache_tag[way][w_hitcheck_index] == w_hitcheck_tag);
        end else begin
          w_hitcheck_hitway[way]    = r_hitcheck_hitway[way];
        end
      end
    end
  endgenerate

  always_comb begin
    if(w_hitcheck_cke) begin
      w_hitcheck_miss   = ~|w_hitcheck_hitway;
      w_hitcheck_valid  = i_load_valid & ~w_hitcheck_miss;
      w_o_fetch_valid   = i_load_valid & w_hitcheck_miss;
    end else begin
      w_hitcheck_miss   = r_hitcheck_miss;
      w_hitcheck_valid  = r_hitcheck_valid;
      w_o_fetch_valid   = o_fetch_valid;
    end
  end

  always_ff @(posedge i_clk) begin
    r_hitcheck_hitway   <=  w_hitcheck_hitway;
    r_hitcheck_miss     <=  w_hitcheck_miss;
    r_hitcheck_valid    <= w_hitcheck_valid;
    o_fetch_valid       <= w_o_fetch_valid;
  end

  // Handshake Logic
  always_comb begin
    w_hitcheck_ready    = i_fetch_ready & w_load_ready;
    w_hitcheck_cke      = ~r_i_load_valid | w_hitcheck_ready;
    o_load_ready        = w_hitcheck_cke;
    if(w_hitcheck_cke) begin
      w_i_load_valid    = i_load_valid;
    end else begin
      w_i_load_valid    = r_i_load_valid;
    end
  end

  always_ff @(posedge i_clk) begin
    r_i_load_valid      <= w_i_load_valid;
  end


  // Send Address to Fetch Stage
  always_comb begin
    if(w_hitcheck_cke) begin
      w_hitcheck_addr    = i_load_addr;
    end else begin
      w_hitcheck_addr    = r_hitcheck_addr;
    end
  end

  always_ff @(posedge i_clk) begin
    o_fetch_addr    <= w_hitcheck_addr;
    r_hitcheck_addr <= w_hitcheck_addr; // nanika ni tsukau kamo
  end

  // Send Address to Load Stage
  always_comb begin
    if(w_hitcheck_cke) begin
      w_hitcheck_tag        = i_load_addr[ADDR_WIDTH-1:ADDR_WIDTH-TAG_WIDTH];
      w_hitcheck_index      = i_load_addr[INDEX_WIDTH+LINEOFFSET_WIDTH-1:LINEOFFSET_WIDTH];
      w_hitcheck_lineoffset = i_load_addr[LINEOFFSET_WIDTH-1:0];
    end else begin
      w_hitcheck_tag        = r_hitcheck_tag;
      w_hitcheck_index      = r_hitcheck_index;
      w_hitcheck_lineoffset = r_hitcheck_lineoffset;
    end
  end

  always_ff @(posedge i_clk) begin
    r_hitcheck_tag          <= w_hitcheck_tag;
    r_hitcheck_index        <= w_hitcheck_index;
    r_hitcheck_lineoffset   <= w_hitcheck_lineoffset;
  end

  // Cache Algorithm
  generate
    for(genvar way = 0; way < WAY_NUM; way = way + 1) begin : CHECK_INVALID_WAY
      always_comb begin
        w_valid_way[way]    = r_cache_valid[way][w_hitcheck_index];
      end
    end
  endgenerate

  KVLRU #(
    .WAY_NUM    (WAY_NUM    ),
    .LINE_NUM   (LINE_NUM   )
  ) LRU (
    .i_clk      (i_clk              ),
    .i_rstn     (),
    .i_hitway   (w_hitcheck_hitway  ),
    .i_index    (w_hitcheck_index   ),
    .o_killmask (w_lru_killmask     )
  );

  always_comb begin
    if(&w_valid_way) begin  // All line is valid
      w_killmask    = w_lru_killmask;
    end else begin
      w_killmask    = w_invalid_killmask;
    end
  end

  always_ff @(posedge i_clk) begin
    r_killmask  <= w_killmask;
  end

  KVSelectInvalidWay #(
    .WAY_NUM    (WAY_NUM    )
  ) SelectInvalidWay (
    .i_valid_way    (w_valid_way        ),
    .o_killmask     (w_invalid_killmask )
  );

  // Fetch Stage
  // Handshake Logic
  always_comb begin
    w_fetch_cke     = ~r_fetch_valid | w_load_ready;
    o_fetch_ready   = w_fetch_cke;
    if(w_fetch_cke) begin
      w_fetch_valid = i_fetch_valid;
    end else begin
      w_fetch_valid = r_fetch_valid;
    end
  end

  always_ff @(posedge i_clk) begin
    r_fetch_valid   <= w_fetch_valid;
  end

  // Send Data to Load Stage
  always_comb begin
    if(w_fetch_cke) begin
      w_fetch_lineoffset    = r_hitcheck_lineoffset;
      w_load_data           = i_fetch_data;
    end else begin
      w_fetch_lineoffset    = r_fetch_lineoffset;
      w_load_data           = r_load_data;
    end
  end

  always_ff @(posedge i_clk) begin
    r_fetch_lineoffset  <= w_fetch_lineoffset;
    r_load_data         <= w_load_data;
  end

  // Store Data to Cache from Memory
  generate
    for(genvar way = 0; way < WAY_NUM; way = way + 1) begin : FETCH_LOGIC
      always_comb begin
        if(i_fetch_valid && r_killmask[way] && w_fetch_cke) begin
          w_cache_valid[way]    = i_fetch_valid;
          w_cache_tag[way]      = r_hitcheck_tag;
          w_cache_line[way]     = i_fetch_data;
        end else begin
          w_cache_valid[way]    = r_cache_valid[way][r_hitcheck_index];
          w_cache_tag[way]      = r_cache_tag[way][r_hitcheck_index];
          w_cache_line[way]     = r_cache_line[way][r_hitcheck_index];
        end
      end
    end
  endgenerate

  generate
    for(genvar way = 0; way < WAY_NUM; way = way + 1) begin : FETCH_TO_CACHE
      always_ff @(posedge i_clk) begin
        r_cache_valid[way][r_hitcheck_index]    <= w_cache_valid[way];
        r_cache_tag[way][r_hitcheck_index]      <= w_cache_tag[way];
        r_cache_line[way][r_hitcheck_index]     <= w_cache_line[way];
      end
    end
  endgenerate


  // Load Stage
  // Handshake Logic
  always_comb begin
    w_load_cke      = ~o_load_valid | i_load_ready;
    w_load_ready    = w_load_cke;
    if(w_load_cke) begin
      w_o_load_valid    = r_hitcheck_valid | r_fetch_valid;
    end else begin
      w_o_load_valid    = o_load_valid;
    end
  end

  always_ff @(posedge i_clk) begin
    o_load_valid    <= w_o_load_valid;
  end

  // Load Logic 
  generate
    for(genvar way = 0; way < WAY_NUM; way = way + 1) begin : LOAD_LOGIC
      always_comb begin
        w_rdataway[way] = r_cache_line[way][r_hitcheck_index][r_hitcheck_lineoffset];
      end
    end
  endgenerate

  // Select Hit Data
  KVPriorityTree #(
    .DATA_WIDTH (DATA_WIDTH ),
    .DATA_NUM   (WAY_NUM    )
  ) SelectReadDataWay (
    .i_datas    (w_rdataway         ),
    .i_valid    (r_hitcheck_hitway  ),
    .o_data     (w_rdata            )
  );

  // Send Data to Processor
  always_comb begin
    if(w_load_cke) begin
      if(r_fetch_valid) begin
        w_o_load_data   = r_load_data[r_fetch_lineoffset];
      end else begin
        w_o_load_data   = w_rdata; 
      end
    end else begin
      w_o_load_data     = o_load_data;
    end
  end

  always_ff @(posedge i_clk) begin
    o_load_data     <= w_o_load_data;
  end

  // Store Logic
  always_comb begin

  end


  // Write Logic
  always_comb begin

  end

endmodule
