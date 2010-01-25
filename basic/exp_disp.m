function exp_disp(exp, obj_types)
%EXP_DISP  Display a summary of an experiment.
%
%  exp_disp(exp, obj_types)
%
%  INPUTS:
%        exp:  an experient object.
%
%  obj_types:  string or cell array of strings giving the object type(s)
%              to print.  Can include: 'subj', 'ev', or 'pat'.

% input checks
if ~exist('obj_types', 'var')
  obj_types = {'exp', 'ev', 'pat', 'subj'};
elseif ~iscell(obj_types)
  obj_types = {obj_types};
end

% formatting settings
id_width = 5;
id = sprintf('%%%ii) %%s', id_width);

fprintf('%-17s%s\n', 'Experiment name', exp.experiment)
fprintf('%-17s%s\n', 'Filename', exp.file)
fprintf('%-17s%s\n', 'Last Saved', exp.lastUpdate)
fprintf('\n')

% print each requested object type
for i=1:length(obj_types)
  switch obj_types{i}
    
   case {'ev', 'events'}
    if ~isfield(exp, 'ev') || isempty(exp.ev)
      continue
    end
    
    ev_dim_labels = {'events'};
    fprintf(print_obj(exp, 'ev', 'Experiment Events', ev_dim_labels,  ...
                     sort({exp.ev.name})))

   case {'pat', 'patterns'}
    if ~isfield(exp, 'pat') || isempty(exp.pat)
      continue
    end
    
    pat_dim_labels = {'events', 'chans', 'time', 'freq'};
    fprintf(print_obj(exp, 'pat', 'Experiment Patterns', pat_dim_labels, ...
                      sort({exp.pat.name})))
    
   case {'subj', 'subject'}
    if ~isfield(exp, 'subj') || isempty(exp.subj)
      continue
    end
    
    % get the types specified, in the proper order
    possible_types = {'subj', 'ev', 'pat'};
    subj_obj_types = possible_types(ismember(possible_types, obj_types));
    subj_disp(exp.subj, subj_obj_types)
  end
end

