KVCache:
	verilator --binary --trace KVCache_tb.sv ../rtl/KVPriorityTree.sv ../rtl/KVCache.sv
	cd obj_dir ; ./VKVCache_tb

KVPriorityTree:
	verilator --binary --trace KVPriorityTree_tb.sv ../rtl/KVPriorityTree.sv
	cd obj_dir ; ./VKVPriorityTree_tb
clean:
	rm -r obj_dir

view:
	gtkwave ./obj_dir/wave.vcd
