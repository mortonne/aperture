function bins = makeBins(stepSize,start,final)
	
	nbins = fix((final+stepSize-start)/stepSize);
	bins = NaN(nbins,2);
	s = start;
	for i=1:nbins
		bins(i,1) = s;
		e = s+stepSize;
		bins(i,2) = e;
		s = e;
	end
	