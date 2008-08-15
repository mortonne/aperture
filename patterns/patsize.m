function psize = patsize(dim)
%PATSIZE   Get the size of a pattern from its dim struct.
%   PSIZE = PATSIZE(DIM) returns the size of the pattern
%   corresponding to DIM.
%
	
psize(1) = dim.ev.len;
psize(2) = length(dim.chan);
psize(3) = length(dim.time);
psize(4) = length(dim.freq);
