function obj = getobj2(s,varargin)

obj = getobj(s,path{1},path{2});

if length(path)>2
  obj = getobj(obj,path{3},path{4});
end
