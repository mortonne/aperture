function val = getValFromStruct(s,fname,default)
%GETVALFROMSTRUCT 
% 
if isfield(s,fname)
  val = s.(deblank(fname));
else
  val = default;
end
