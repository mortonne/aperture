function params = list2propval(args, defaults, varargin)
%LIST2PROPVAL   Take input from a list, property value pairs, or a struct.
%
%  This function is designed to handle cases where a function is being
%  moved to having property, value style inputs using varargin, but one
%  needs to maintain backward compatibility. It will attempt to guess
%  the type of input; if class is specified for each input, this
%  guessing will be accurate in most possible cases. If class is not
%  specified, the function will be fooled by list inputs that look
%  like property, value pairs, i.e. where every other input is a char.
%
%  If you specify the classes of all possible inputs and the first
%  list-style input is not a char, input will always be unambiguous. If
%  it is a char, be careful using this function.
%
%  params = list2propval(args, defaults, ...)
%
%  INPUTS:
%      args:  cell array of inputs (list), struct with a field for each
%             input (struct), or cell array of property, value pairs.
%
%  defaults:  struct listing default value of all possible input args.
%
%  OUTPUTS:
%    params:  struct with the args, and any defaults set.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   fields       - cell array of strings giving the name for each input,
%                  in the same order as list-style inputs.
%                  (fieldnames(defaults))
%   classes      - cell array of strings indicating the class of each
%                  input. Any cell may also be a cell array of strings,
%                  if an input has multiple valid classes. If not
%                  specified, a list input will be assumed if every
%                  other input is a string. ({})
%   init_fields  - cell array of strings giving fieldnames for the first
%                  N items in propval input. ({})
%   init_classes - cell array of strings giving the classes for the
%                  first N items in propval input. ({})
%   strict       - if true, an error will be thrown if args lacking
%                  defaults are passed in. (true)

if ~exist('defaults', 'var')
  defaults = struct;
end

% options
defs.fields = fieldnames(defaults);
defs.classes = {};
defs.init_fields = {};
defs.init_classes = {};
defs.strict = true;
opt = propval(varargin, defs);

if isstruct(args)
  % the easy case; just call propval
  params = propval(args, defaults, 'strict', opt.strict);
  return
end

if ~iscell(args)
  error('args must be a struct or a cell array.')
end

if isempty(args)
  % no need for guesswork
  params = propval(args, defaults, 'strict', opt.strict);
  return
end

% check if the classes match the list classes (strictest test for lists)
if ~isempty(opt.classes) && length(args) > length(opt.classes)
  % more arguments than classes; must be propval
  arg_type = 'propval';
elseif ~isempty(opt.classes)
  class_match = true;
  for i = 1:length(args)
    if iscellstr(opt.classes{i})
      % multiple possible classes
      match = false(1, length(opt.classes{i}));
      for j = 1:length(opt.classes{i})
        match(j) = isa(args{i}, opt.classes{i}{j});
      end
      if ~any(match)
        class_match = false;
        break
      end
      
    elseif ~isa(args{i}, opt.classes{i})
      % only one possible class
      class_match = false;
      break
    end
  end

  if class_match
    arg_type = 'list';
  else
    arg_type = 'propval';
  end
elseif ~isempty(opt.init_classes) && length(args) < length(opt.init_classes)
  arg_type = 'list';
elseif ~isempty(opt.init_classes)
  % check if the inputs match the class of initial inputs for propval
  class_match = true;
  for i = 1:length(opt.init_classes)
    if ~isa(args{i}, opt.init_classes{i})
      class_match = false;
      break
    end
  end
  
  if class_match
    arg_type = 'propval';
  else
    arg_type = 'list';
  end
elseif mod(length(args), 2) ~= 0
  % odd number of inputs; must not be propval
  arg_type = 'list';
elseif opt.strict && length(args) > length(opt.fields)
  % more inputs than defaults; must not be a list
  arg_type = 'propval';
else
  % check for a sign that these are property, value pairs. This test is
  % not conclusive, but we have to take a guess
  arg_classes = cellfun(@class, args, 'UniformOutput', false);
  if all(strcmp('char', arg_classes(1:2:end)))
    arg_type = 'propval';
  else
    % if every other input isn't a string, assume a list
    arg_type = 'list';
  end
end

% now that we've guessed the input type, process the args
switch arg_type
 case 'list'
  for i = 1:length(args)
    arg_struct.(opt.fields{i}) = args{i};
  end
  params = propval(arg_struct, defaults, 'strict', opt.strict);
 case 'propval'
  if ~isempty(opt.init_classes)
    if isempty(opt.init_fields)
      error('if init_classes is defined, init_fields must be defined also')
    end
    for i = 1:length(opt.init_fields)
      defaults.(opt.init_fields{i}) = args{i};
    end
    args = args(length(opt.init_fields) + 1:end);
  end
  params = propval(args, defaults, 'strict', opt.strict);
end

