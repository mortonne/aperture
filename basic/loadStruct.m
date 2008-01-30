function s = loadStruct(structFile, repStr)
%
%LOADSTRUCT - load a structure from file, and recursively (for up
%to three levels in) replace a string found anywhere in the struct 
%with a new string.  Useful for bringing a struct with file
%references from a remote machine to a local machine.
%
% FUNCTION: s = loadStruct(structFile, repStr)
%
% Examples:
%
% structFile = '/Volumes/mortonne/EXPERIMENTS/catFR/pow_pattern3/eeg.mat';
% repStr = {'/data1' '/Volumes/hippo/data1'; '~/' '/Volumes/mortonne/'};
% eeg = loadStruct(structFile,repStr);
%
% structFile = '/Volumes/hippo/home1/mortonne/EXPERIMENTS/catFR/pow_pattern3/eeg.mat';
% repStr = {'/data1' '/Volumes/hippo/data1'; '~/' '/Volumes/hippo/home1/mortonne/'};
% eeg = loadStruct(structFile,repStr);
%

struct = load(structFile);
struct_name = fieldnames(struct);
s = getfield(struct, struct_name{1});

if nargin==2 & ~isempty(repStr) & isstruct(s)

  F1s = fieldnames(s);
  for a=1:length(s)
    for x=1:length(F1s)
      Fname1 = F1s{x};
      F1 = getfield(s(a), Fname1);
      
      % replace string
      if isstr(F1) 
	for r=1:size(repStr, 1)
	  s(a) = setfield(s(a), Fname1, strrep(getfield(s(a), Fname1), repStr{r,1}, repStr{r,2}));
	end
      end
      
      if iscell(F1)
	for k=1:length(F1)
	  for r=1:size(repStr, 1)
	    F1{k} = strrep(F1{k}, repStr{r,1}, repStr{r,2});
	  end
	end
	s(a) = setfield(s(a), Fname1, F1);
      end
      
      % check all fields
      if isstruct(F1) 
	
	F2s = fieldnames(F1);
	for b=1:length(F1)
	  for y=1:length(F2s)
	    Fname2 = F2s{y};
	    F2 = getfield(F1(b), Fname2);
	    
	    % replace string
	    if isstr(F2) 
	      for r=1:size(repStr, 1)
		F1(b) = setfield(F1(b), Fname2, strrep(getfield(F1(b), Fname2), repStr{r,1}, repStr{r,2}));
	      end
	    end
	    
	    if iscell(F2)
	      for k=1:length(F2)
		for r=1:size(repStr, 1)
		  F2{k} = strrep(F2{k}, repStr{r,1}, repStr{r,2});
		end
	      end
	      F1(b) = setfield(F1(b), Fname2, F2);
	    end
	    
	    % check all fields
	    if isstruct(F2) 
	      
	      F3s = fieldnames(F2);
	      for c=1:length(F2)
		for z=1:length(F3s)
		  Fname3 = F3s{z};
		  F3 = getfield(F2(c), Fname3);
		  
		  if iscell(F3)
		    for k=1:length(F3)
		      for r=1:size(repStr, 1)
			F3{k} = strrep(F3{k}, repStr{r,1}, repStr{r,2});
		      end
		    end
		    F2(c) = setfield(F2(c), Fname3, F3);
		  end
		  
		  % replace string
		  if isstr(F3) 
		    for r=1:size(repStr, 1)
		      F2(c) = setfield(F2(c), Fname3, strrep(getfield(F2(c), Fname3), repStr{r,1}, repStr{r,2}));
		    end
		  end
		  
		  
		  if isstruct(F3)
		    
		    F4s = fieldnames(F3);
		    for d=1:length(F3)
		      for q=1:length(F4s)
			Fname4 = F4s{q};
			F4 = getfield(F3(d), Fname4);
			
			if iscell(F4)
			  for k=1:length(F4)
			    for r=1:size(repStr, 1)
			      F4{k} = strrep(F4{k}, repStr{r,1}, repStr{r,2});
			    end
			  end
			  F3(d) = setfield(F3(d), Fname4, F4);
			end
			
			% replace string
			if isstr(F4) 
			  for r=1:size(repStr, 1)
			    F3(d) = setfield(F3(d), Fname4, strrep(getfield(F3(d), Fname4), repStr{r,1}, repStr{r,2}));
			  end
			end
			
		      end
		    end
		  end
		  F2(c) = setfield(F2(c), Fname3, F3);
		  
		end
	      end
	      F1(b) = setfield(F1(b), Fname2, F2);
	    
	    end
	  end
	  s(a) = setfield(s(a), Fname1, F1);	

	end
      end
      
    end    
  end
  
end

