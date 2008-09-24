function exp = applytosubj(exp,objtype,objname,varargin)
%APPLYTOSUBJ   Apply a function to all subjects.
%   EXP = APPLYTOSUBJ(EXP,OBJTYPE,OBJNAME,VARARGIN) gets the object
%   of type OBJTYPE and name OBJNAME from each subject, and passes
%   it into one or more functions.  Functions are specified by
%   function handle, input argument cell array pairs.  The first input
%   into each function will be the object.  After each function has
%   been run, setobj is used to add the object onto subj.
%
%   Example
%     To apply myfunction to each subject's voltage pattern:
%     exp = applytosubj(exp,'pat','voltage',@myfunction,{arg1,arg2,arg3})
%

fprintf('Processing %s:',exp.experiment)
for s=1:length(exp.subj)
  subj = exp.subj(s);
  fprintf('\n%s: ', subj.id)
  
  % get the pat to modify
  obj = getobj(subj, objtype, objname);
  if isempty(obj)
    warning('%s object %s not found.', objtype, objname)
    continue
  end
  
  obj.source = subj.id;
  
  for i=1:2:length(varargin)
    if i>1
      fprintf('\n\t')
    end
    
    % get the function to evaluate
    objmodfcn = varargin{i};
    fcnstr = func2str(objmodfcn);
    
    if exist(fcnstr)~=2
      error('Unknown function %s.', fcnstr)
    end
    
    % get other inputs, if there are any
    if i<length(varargin)
      inputs = varargin{i+1};
      if ~iscell(inputs)
        inputs = {inputs};
      end
      
      else
      inputs = {};
    end
    
    fprintf('Running %s...', fcnstr)
    
    % eval the function, using the object and the cell array of inputs
    [obj,err] = objmodfcn(obj, inputs{:});
    
    if err>1
      % this subject failed; may be locked
      fprintf('skipping %s...\n', subj.id)
      break
    end
  end
  
  if err>1
    continue
  end
  
  exp.subj(s) = setobj(exp.subj(s),objtype,obj);
end
fprintf('\n')

exp = update_exp(exp);
