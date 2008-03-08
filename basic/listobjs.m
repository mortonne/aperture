function objnames = listobjs(s,f)
%objnames = listobjs(s,f)

objs = getfield(s,f);
if ~isstruct(objs)
  error('Field is not a struct.');
end

try
  objnames = getStructField(objs, 'name');
catch
  objnames = getStructField(objs, 'id');
end
