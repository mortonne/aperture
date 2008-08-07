function exp = applytosubj(exp,objtype,objname,varargin)
% MOD_SUBJ_PAT   Short description
%   [EXP] = MOD_SUBJ_PAT(EXP,PATNAME,VARARGIN)
%
% Long description
% 
% Created by Neal Morton on 2008-08-04.
%

for subj=exp.subj
  fprintf('\n%s\n', subj.id)
  running = 1;
  
  % get the pat to modify
  obj = getobj(subj, objtype, objname);
  obj.source = subj.id;
  
  for i=1:2:length(varargin)
    % get the function to evaluate
    objmodfcn = varargin{i};
    
    % get other inputs, if there are any
    if i<length(varargin)
      inputs = varargin{i+1};
      if ~iscell(inputs)
        inputs = {inputs};
      end
      
      else
      inputs = {};
    end
    
    fprintf('Running %s...\n', func2str(objmodfcn))
    
    % eval the function, using the object and the cell array of inputs
    obj = objmodfcn(obj, inputs{:});
    
    if isempty(obj)
      % this subject failed; may be locked
      fprintf('Skipping %s...\n', subj.id)
      running = 0;
      break
    end
  end
  
  if ~running
    continue
  end
  
  % update the exp struct with the new pat object
  exp = update_exp(exp, 'subj', subj.id, objtype, obj);
end
