function subj_disp(subj, obj_types)
%SUBJ_DISP   Display a summary of a subject or group of subjects.
%
%  subj_disp(subj, obj_types)
%
%  INPUTS:
%       subj:  a subject structure.  May be a single subject object or a
%              vector of subject objects.
%
%  obj_types:  string or cell array of strings giving the object type(s)
%              to print.  Can include: 'subj', 'ev', or 'pat'.

% input checks
if ~exist('obj_types', 'var')
  obj_types = {'subj', 'ev', 'pat'};
elseif ~iscell(obj_types)
  obj_types = {obj_types};
end

% formatting settings
id_width = 5;
id = sprintf('%%%ii) %%s', id_width);

% print each requested object type
for i=1:length(obj_types)
  switch obj_types{i}    
   case {'subj', 'subject'}
    % print information for all subjects
    dim_labels = {'nSess', 'nChan'};
    dummy_obj.subj = subj;
    fprintf(print_obj(dummy_obj, 'subj', 'Subjects', dim_labels, ...
                      sort({subj.id})));
    
   case {'ev', 'events'}
    if ~isfield(subj, 'ev')
      continue
    end
    
    % get events names for all subjects
    ev_dim_labels = {'events'};
    evs = cell(1, length(subj));
    for i=1:length(subj)
      if isempty(subj(i).ev)
        continue
      end      
      evs{i} = {subj(i).ev.name};
    end
    ev_names = unique([evs{:}]);
    
    % print
    fprintf(print_obj(subj, 'ev', 'Subject Events', {'events'}, ev_names));
    
   case {'pat', 'patterns'}
    if ~isfield(subj, 'pat')
      continue
    end
    
    % get pattern names for all subjects
    pat_dim_labels = {'events', 'chans', 'time', 'freq'};
    pats = cell(1, length(subj));
    for i=1:length(subj)
      if isempty(subj(i).pat)
        continue
      end
      pats{i} = {subj(i).pat.name};
    end
    pat_names = unique([pats{:}]);
    
    % print
    fprintf(print_obj(subj, 'pat', 'Subject Patterns', pat_dim_labels, ...
                      pat_names));
   otherwise
    error('Unknown object type: ''%s''', obj_types{i})
  end
end

