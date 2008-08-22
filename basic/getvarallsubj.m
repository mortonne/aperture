function varargout = getvarallsubj(exp,patname,objtype,objname,varnames)
%GETVARALLSUBJ
%   VARARGOUT = GETVARALLSUBJ(EXP,PATNAME,OBJTYPE,OBJNAME,VARNAMES)

if ~exist('varnames','var')
  varnames = {};
end
if ~iscell(varnames)
  varnames = {varnames};
end

% load the vars
for s=1:length(exp.subj)
  if isempty(exp.subj(s).pat)
    continue
  end
  
  pat = getobj(exp.subj(s),'pat',patname);
  if isempty(pat)
    continue
    %error('pat object %s not found.', patname)
  end
  
  obj = getobj(pat,objtype,objname);
  if isempty(obj)
    error('%s object %s not found.', objtype, objname)
  end
  
  if ~isempty(varnames)
    varstruct(s) = load(obj.file,varnames{:});
    else
    varstruct(s) = load(obj.file);
  end
end

if ~exist('varstruct','var')
  error('Error!')
end

if ~isempty(varnames)
  varstruct = orderfields(varstruct,varnames);
end

% convert to a varsXsubjects cell array
varcell = shiftdim(struct2cell(varstruct),1);

for i=1:size(varcell,1)
  varargout{i} = [];
  for j=1:size(varcell,2)
    try
      varargout{i} = [varargout{i}; varcell{i,j}];
      catch
      warning('Skipping %s.', exp.subj(j).id)
    end
  end
end
