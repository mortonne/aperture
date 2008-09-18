function varargout = getvarallsubj(exp,path,varnames)
%GETVARALLSUBJ
%   VARARGOUT = GETVARALLSUBJ(EXP,PATH,VARNAMES)

if ~exist('varnames','var')
  varnames = {};
end
if ~iscell(varnames)
  varnames = {varnames};
end

% load the vars
fprintf('Exporting from subjects...')
for s=1:length(exp.subj)
  fprintf('%s ', exp.subj(s).id)

  obj = getobj2(exp.subj(s),path);
  if isempty(obj)
    continue
    %error('pat object %s not found.', patname)
  end
  
  if isempty(obj)
    error('')
    %error('%s object %s not found.', objtype, objname)
  end
  
  if ~isempty(varnames)
    varstruct(s) = load(obj.file,varnames{:});
    else
    varstruct(s) = load(obj.file);
  end
end
fprintf('\n')

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
      if size(varcell{i,j},1)==1
        varargout{i} = [varargout{i} varcell{i,j}];
        else
        varargout{i} = [varargout{i}; varcell{i,j}];
      end
      catch
      warning('Skipping %s.', exp.subj(j).id)
    end
  end
end
