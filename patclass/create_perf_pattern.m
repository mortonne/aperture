function pat = create_perf_pattern(pat, stat_name, varargin)
%CREATE_PERF_PATTERN   Create a pattern from classifier outputs.
%
%  From the results of pattern classification, get a pattern containing
%  a measure of classifier performance. The classifier output can then
%  be manipulated and plotted in all of the ways that any other pattern
%  can.
%
%  pat = create_perf_pattern(pat, stat_name, ...)
%
%  INPUTS:
%        pat:  a pattern object.
%
%  stat_name:  name of a stat object attached to pat that contains
%              results of pattern classification (created using
%              classify_pat or classify_pat2pat).
%
%  OUTPUTS:
%        pat:  the new pattern object.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   stat_type    - the type of classification statistic to include in
%                  the pattern. Can be:
%                   'perf'    - use an already-calculated performance
%                               metric. Will be one "event" for each
%                               cross-validation iteration (default)
%                   'acts'    - value of an output unit. Use
%                               class_output to specify which unit to
%                               return (see below)
%                   'guess'   - condition guessed by the classifier
%                   'correct' - logical array indicating whether the
%                               classifier was correct
%                  May also be a function handle to a performance metric
%                  function, which will be applied to each event_bin.
%   class_output - if stat_type is 'acts', specifies which output units
%                  to return. Can be:
%                   numeric     - index of the output unit in the acts
%                                 matrix
%                   'fieldname' - name of an events field containing the
%                                 label of the output unit to get for a
%                                 given event
%                   'correct'   - the output unit for the correct
%                                 category on a given event
%   event_bins   - input to make_event_bins to define subsets of events
%                  to apply the perfmet function to (only used if
%                  stat_type is a function handle). Default is to
%                  calculate the perfmet for each iteration.
%   event_labels - cell array of strings, with one cell per bin. Gives
%                  a label for each event bin. ({})
%   event_levels - cell array of cell arrays of strings. Used only if
%                  specifying bins as a conjunction of multiple
%                  factors, e.g. two events fields. The label for
%                  factor i, level j goes in event_levels{i}{j}.
%                  ({})
%   precision    - precision of the created pattern.
%                  [{'single'} | 'double']
%   save_mats    - if true, and input mats are saved on disk, modified
%                  mats will be saved to disk. If false, the modified
%                  mats will be stored in the workspace, and can
%                  subsequently be moved to disk using move_obj_to_hd.
%                  (true)
%   overwrite    - if true, existing patterns on disk will be
%                  overwritten. (true)
%   save_as      - string identifier to name the modified pattern. If
%                  empty, the name will not change.
%                  ([pat.name '-' stat_name])
%   res_dir      - directory in which to save the modified pattern and
%                  events, if applicable. Default is a directory named
%                  pat_name on the same level as the input pat.

% input checks
if ~exist('pat', 'var') || ~isstruct(pat)
  error('You must pass a pattern object.')
elseif ~exist('stat_name', 'var') || ~ischar(stat_name)
  error('You must pass the name of the stat object to use.')
end

stat = getobj(pat, 'stat', stat_name);

% set params
defaults.stat_type = 'perf';
defaults.class_output = 'correct';
if isfield(stat.params, 'selector')
  defaults.event_bins = stat.params.selector;
else
  defaults.event_bins = [];
end
defaults.event_labels = {};
defaults.event_levels = {};
defaults.precision = 'single';
defaults.save_as = [pat.name '-' stat_name];
defaults.overwrite = true;
[params, saveopts] = propval(varargin, defaults);

saveopts = propval(saveopts, struct, 'strict', false);
saveopts.save_as = params.save_as;
saveopts.overwrite = params.overwrite;
params = rmfield(params, {'save_as', 'overwrite'});

% make the new pattern
pat = mod_pattern(pat, @get_patclass_stats, {stat_name, params}, saveopts);

function pat = get_patclass_stats(pat, stat_name, params)
  % get the results of pattern classification
  stat = getobj(pat, 'stat', stat_name);
  res = get_stat(stat, 'res');
  [n_iter, n_chans, n_time, n_freq] = size(res.iterations);
  
  % sanity check events
  train_events = length(res.iterations(1).train_idx);
  test_events = length(res.iterations(1).test_idx);
  if train_events ~= test_events
    class_events = train_events + test_events;
  else
    class_events = train_events;
  end
  pat_events = patsize(pat.dim, 1);
  assert(class_events == pat_events, ...
         'different numbers of events in the pattern and classification.');
  
  % fix (non-event) dimensions that were binned during classification
  bin_params = struct;
  if isfield(stat.params, 'iter_bins') && ~isempty(stat.params.iter_bins)
    bin_params = merge_structs(bin_params, stat.params.iter_bins);
  end
  if isfield(stat.params, 'sweep_bins') && ~isempty(stat.params.sweep_bins)
    bin_params = merge_structs(bin_params, stat.params.sweep_bins);
  end
  if ~isempty(fieldnames(bin_params))
    % use all bins used for iter or sweep (should not overlap)
    temp = patBins(pat, bin_params);
    pat.dim = temp.dim;
  end
  
  % get non-singleton dimentions of res
  pat_size = patsize(pat.dim);
  class_size = [n_iter n_chans n_time n_freq];
  
  non_sing = find(class_size > 1);
  all_dims = 2:4;
  sing_dims = all_dims(~ismember(all_dims, non_sing));
  non_sing = non_sing(~ismember(non_sing, 1));
  for i = 1:length(non_sing)
    if class_size(non_sing(i)) ~= pat_size(non_sing(i))
      error('Class results and pattern do not match on %s dimension.', ...
            read_dim_input(non_sing(i)))
    end
  end
  
  % collapse the dimensions that were collapsed during classification
  % (not including events)
  for d = sing_dims
    dim_name = read_dim_input(d);
    switch dim_name
     case 'chan'
      dim = struct('number',[], 'region','', 'label','');
     case 'time'
      dim = init_time(1);
     case 'freq'
      dim = init_freq(1);
     otherwise
      error('Unknown dimension type: %s.', dim_name)
    end
    
    pat.dim.(dim_name) = dim;
  end

  % collapse events to match the classification results
  if strcmp(params.stat_type, 'perf')
    % one event for each iteration
    n_events = n_iter;
    
    % bin the events dimension
    if n_iter > 1
      % assume xval
      temp = patBins(pat, 'eventbins', stat.params.selector);
    else
      % assume pat2pat
      temp = patBins(pat, 'eventbins', 'overall');
    end
    pat.dim = temp.dim;
  
  elseif isa(params.stat_type, 'function_handle') && ...
        ~isempty(params.event_bins)
    % bin the events dimension
    [temp, bins] = patBins(pat, 'eventbins', params.event_bins, ...
                           'eventbinlabels', params.event_labels, ...
                           'eventbinlevels', params.event_levels);
    event_bins = bins{1};
    n_events = length(event_bins);
    pat.dim = temp.dim;
  else
    
    % events don't change
    n_events = patsize(pat.dim, 'ev');
  end

  % if getting classifier estimates, add an events field for accessing
  % the correct unit
  if strcmp(params.stat_type, 'acts') && ~isempty(params.class_output)
    if ischar(params.class_output) && ...
             ~strcmp(params.class_output, 'correct')
      % getting from field
      output_field = params.class_output;
      field_val = output_field;
    elseif isnumeric(params.class_output)
      % getting a specified unit
      field_val = num2str(params.class_output);
    elseif ischar(params.class_output) && ...
           strcmp(params.class_output, 'correct')
      % correct output
      field_val = params.class_output;
    end
    
    % add this info to the events structure
    events = get_dim(pat.dim, 'ev');
    [events.class] = deal(field_val);
    pat.dim = set_dim(pat.dim, 'ev', events, 'ws');
  end
  
  % define bins for calculating a new performance metric
  if isa(params.stat_type, 'function_handle')
    if ~isempty(params.event_bins)
      iter_cell = {[], event_bins, []};
    else
      iter_cell = {[], 'iter', []};
    end
  end
  
  % initialize the new pattern
  pattern = NaN(n_events, n_chans, n_time, n_freq, params.precision);

  % create a pattern with classifier outputs
  fprintf('creating pattern from "%s" "%s" classification results...\n', ...
          pat.name, stat_name)
  for c = 1:n_chans
    for t = 1:n_time
      for f = 1:n_freq
        if strcmp(params.stat_type, 'perf')
          % just use the already-calculated perfmet
          pattern(:,c,t,f) = [res.iterations(:,c,t,f).perf];
        
        elseif ischar(params.stat_type)
          % get some statistic for each event
          if exist('output_field', 'var')
            % this is a field from the events structure
            inputs{1} = [events.(output_field)];
            inputs{2} = nanunique(inputs{1});
          else
            inputs = {params.class_output};
          end
          pattern(:,c,t,f) = get_acts(res.iterations(:,c,t,f), ...
                                      params.stat_type, inputs{:});
          
        elseif isa(params.stat_type, 'function_handle')
          % calculate a new perfmet
          f_perfmet = params.stat_type;
          [acts, targs] = get_class_stats(res.iterations(:,c,t,f));
          
          perf = apply_by_group(@calc_perf, {acts, targs}, iter_cell, ...
                                f_perfmet);
          pattern(:,c,t,f) = perf;
          
        else
          error('Invalid stat_type.')
        end
      end
    end
  end

  % add the classifier outputs as the pattern matrix
  pat = set_mat(pat, pattern, 'ws');


function acts = get_acts(res, stat_type, class_output, classes)
%GET_ACTS   Get information from classifier output.
%
%  acts = get_acts(res, stat_type, class_output, classes)

  n_events = length(res(1).test_idx);
  acts = NaN(n_events, 1);
  
  for i = 1:length(res)
    iter_res = res(i);
    missing = all(all(isnan(iter_res.acts), 1), 3);
    
    %if size(iter_res.acts, 3) > 1
    %  error('classification with multiple replications not supported.')
    %end
    
    switch stat_type
     case 'acts'
      if ischar(class_output) && strcmp(class_output, 'correct')
        % get classifier activation for the correct unit
        if all(isnan(iter_res.targs(:)))
          % classification was aborted
          continue
        end
        
        [n_cond, n_obs, n_rep] = size(iter_res.acts);
        [y, correct_targ] = max(iter_res.targs);
        mat = NaN(n_rep, n_obs);
        for j = 1:n_obs
          % get the acts for the correct unit
          mat(:,j) = iter_res.acts(correct_targ(j),j,:);
        end
        
        % average over replications
        mat = nanmean(mat, 1);
        
      elseif isscalar(class_output) && isnumeric(class_output)
        % get the specified unit
        mat = iter_res.acts(class_output, :);
        
      elseif isnumeric(class_output)
        % vector of category labels
        iter_inds = find(iter_res.test_idx);
        n_iter_events = length(iter_inds);
        mat = NaN(n_iter_events, 1);        
        for j = 1:n_iter_events
          this_class = class_output(iter_inds(j));
          act_ind = find(this_class == classes);
          if isempty(act_ind)
            continue
          end
          mat(j) = iter_res.acts(act_ind,j);
        end        
      else
        error('Invalid setting for class_output.')
      end
      
     case 'correct'
      % for each event, get whether the classifier guessed correctly
      perfmet = perfmet_maxclass(iter_res.acts, iter_res.targs);
      mat = perfmet.corrects;
      
     case 'guess'
      % for each event, get the unit that was maximally active
      perfmet = perfmet_maxclass(iter_res.acts, iter_res.targs);
      mat = perfmet.guesses;
      
     case 'rank'
      perfmet = perfmet_rank(iter_res.acts, iter_res.targs);
      mat = perfmet.rank;
    end
    
    mat = double(mat);
    mat(missing) = NaN;
    acts(iter_res.test_idx) = mat;
  end
  
function perf = calc_perf(acts, targs, f_perfmet)
%CALC_PERF   Calculate a classification performance metric.
%
%  perf = calc_perf(acts, targs, f_perfmet)

  if isempty(targs) || isempty(acts)
    perf = NaN;
    return
  end
  
  if size(acts, 3) == 1
    % only one replication
    missing = all(isnan(acts), 1);
    acts = acts(:,~missing);
    targs = targs(:,~missing);
    if isempty(targs) || isempty(acts)
      perf = NaN;
      return
    end
    perfmet = f_perfmet(acts, targs);
    perf = perfmet.perf;
  else
    % multiple replications to average over
    perf = NaN(1, size(acts, 3));
    for i = 1:size(acts, 3)
      missing = all(isnan(acts(:,:,i)), 1);
      perfmet = f_perfmet(acts(:,~missing,i), targs(:,~missing));
      perf(i) = perfmet.perf;
    end
    perf = nanmean(perf);
  end
  
