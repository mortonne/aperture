% function leads=getleads(fname)
% This function reads the files fname and returns the corresponding
% list of leads. If it can't open the file, it returns an empty
% vector.
function leads=getleads(fname)

in=fopen(fname,'r');
leads=[];
if(in~=-1)  
  leads=fscanf(in,'%i',[1,inf]);
  fclose(in);
end

if(isempty(leads)) 
  if exist('lead_coords.txt','file')
    leads=getleadcoords('lead_coords.txt');
  end
end