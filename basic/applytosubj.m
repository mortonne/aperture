function exp = applytosubj(exp,subjects,objtype,objname,varargin)
%APPLYTOSUBJ   Apply a function to all subjects.
%   EXP = APPLYTOSUBJ(EXP,SUBJECTS,OBJTYPE,OBJNAME,VARARGIN) gets the object
%   of type OBJTYPE and name OBJNAME from each subject, and passes
%   it into one or more functions.  Functions are specified by
%   function handle, input argument cell array pairs.  The first input
%   into each function will be the object.  After each function has
%   been run, setobj is used to add the object onto subj.
%
%   Example
%     To apply myfunction to each subject's voltage pattern:
%     exp = applytosubj(exp,[],'pat','voltage',@myfunction,{arg1,arg2,arg3})
%

if isempty(subjects)
  % convert the subject id's to numbers
  subjs = {exp.subj.id};
  usubjs = unique(subjs);
  for s=1:length(usubjs)
    id = usubjs{s};
    subjects(s) = str2num(id(isstrprop(id,'digit')));
  end
  
  elseif ~isnumeric(subjects)
  error('Subjects should be a numeric array.')
end

fprintf('Processing %s:',exp.experiment)
for i=1:length(subjects)
  % get this subject
  [subj,match] = filtersubj(exp.subj,subjects(i));
  s = find(match);
  if length(s)>1
    error('Multiple matches for subject %d',subjects(i))
    elseif length(s)==0
    error('Subject %d not found in exp.subj.')
  end

  if ~isfield(subj, objtype) || isempty(subj.(objtype))
    continue
  end

  fprintf('\n%s: ', subj.id)
  
  % get the pat to modify
  obj = getobj(subj, objtype, objname);
  if isempty(obj)
    warning('%s object %s not found.', objtype, objname)
    continue
  end
  
  obj.source = subj.id;
  
  for j=1:2:length(varargin)
    if j>1
      fprintf('\n\t')
    end
    
    % get the function to evaluate
    objmodfcn = varargin{j};
    fcnstr = func2str(objmodfcn);
    
    if exist(fcnstr)~=2
      error('Unknown function %s.', fcnstr)
    end
    
    % get other inputs, if there are any
    if j<length(varargin)
      inputs = varargin{j+1};
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
