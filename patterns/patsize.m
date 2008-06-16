function psize = patsize(dim)
	
	psize(1) = dim.ev.len;
	psize(2) = length(dim.chan);
	psize(3) = length(dim.time);
	psize(4) = length(dim.freq);
	