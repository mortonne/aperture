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
%   stat_type - the type of classification statistic to include in the
%               pattern. Can be:
%                'perf'    - use an already-calculated performance
%                            metric. Will be one "event" for each
%                            cross-validation iteration (default)
%                'acts'    - value of the output unit for the actual
%                            condition
%                'guess'   - condition guessed by the classifier
%                'correct' - logical array indicating whether the
%                            classifier was correct
%               May also be a function handle to a performance metric
%               function, which will be applied to each event_bin.
%   event_bins - input to make_event_bins to define subsets of events to
%               apply the perfmet function to (only used if stat_type is
%               a function handle). Default is to calculate the
%               perfmet for each iteration.
%   precision - precision of the created pattern. [{'single'} | 'double']
%   save_mats - if true, and input mats are saved on disk, modified
%               mats will be saved to disk. If false, the modified mats
%               will be stored in the workspace, and can subsequently
%               be moved to disk using move_obj_to_hd. (true)
%   overwrite - if true, existing patterns on disk will be overwritten.
%               (true)
%   save_as   - string identifier to name the modified pattern. If
%               empty, the name will not change.
%               ([pat.name '-' stat_name])
%   res_dir   - directory in which to save the modified pattern and
%               events, if applicable. Default is a directory named
%               pat_name on the same level as the input pat.

% input checks
if ~exist('pat', 'var') || ~isstruct(pat)
  error('You must pass a pattern object.')
elseif ~exist('stat_name', 'var') || ~ischar(stat_name)
  error('You must pass the name of the stat object to use.')
end

stat = getobj(pat, 'stat', stat_name);

% set params
defaults.stat_type = 'perf';
defaults.event_bins = stat.params.selector;
defaults.event_levels = {};
defaults.precision = 'single';
defaults.save_as = [pat.name '-' stat_name];
defaults.overwrite = true;
[params, saveopts] = propval(varargin, defaults);
saveopts.save_as = params.save_as;
saveopts.overwrite = params.overwrite;
params = rmfield(params, {'save_as', 'overwrite'});

% make the new pattern
pat = mod_pattern(pat, @get_patclass_stats, {stat_name, params}, saveopts);

function pat = get_patclass_stats(pat, stat_name, params)
  % get the results of pattern classification
  stat = getobj(pat, 'stat', stat_name);
  res = getfield(load(stat.file, 'res'), 'res');
  [n_iter, n_chans, n_time, n_freq] = size(res.iterations);
  
  % sanity check
  class_events = length(res.iterations(1).train_idx);
  pat_events = patsize(pat.dim, 1);
  assert(class_events == pat_events, ...
         'different numbers of events in the pattern and classification.');
  
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
    % one event for each bin
    %events = get_dim(pat.dim, 'ev');
    %event_bins = index2bins(make_event_bins(events, params.event_bins));
    %n_events = length(event_bins);
    %iter_cell = {[], event_bins};
    
    % bin the events dimension
    [temp, bins] = patBins(pat, 'eventbins', params.event_bins, ...
                           'eventbinlevels', params.event_levels);

    event_bins = bins{1};
    n_events = length(event_bins);
    iter_cell = {[], event_bins};
    
    pat.dim = temp.dim;
  else
    
    % events don't change
    n_events = patsize(pat.dim, 'ev');
  end

  % initialize the new pattern
  pattern = NaN(n_events, n_chans, n_time, n_freq, params.precision);

  % create a pattern with classifier outputs
  fprintf('\ncreating pattern from "%s" classification results...', stat_name)

  if isempty(params.event_bins)
    iter_cell = {[], 'iter'};
  end
  
  for c = 1:n_chans
    for t = 1:n_time
      for f = 1:n_freq
        if strcmp(params.stat_type, 'perf')
          % just use the already-calculated perfmet
          pattern(:,c,t,f) = [res.iterations(:,c,t,f).perf];
          
        elseif ischar(params.stat_type)
          % get some statistic for each event
          pattern(:,c,t,f) = get_acts(res.iterations(:,c,t,f), ...
                                      params.stat_type);
          
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

  % get non-singleton dimentions of res
  non_sing = find([n_iter n_chans n_time n_freq] > 1);
  all_dims = 2:4;
  sing_dims = all_dims(~ismember(all_dims, non_sing));

  % fix dimensions that were binned during classification
  bin_params = struct;
  if isfield(stat.params, 'iter_params') && ~isempty(stat.params.iter_params)
    bin_params = merge_structs(bin_params, stat.params.iter_params);
  end
  if isfield(stat.params, 'sweep_params') && ~isempty(stat.params.sweep_params)
    bin_params = merge_structs(bin_params, stat.params.sweep_params);
  end
  if ~isempty(fieldnames(bin_params))
    % use all bins used for iter or sweep (should not overlap)
    temp = patBins(pat, bin_params);
    pat.dim = temp.dim;
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

  % add the classifier outputs as the pattern matrix
  pat = set_mat(pat, pattern, 'ws');


function acts = get_acts(res, stat_type)
  n_events = length(res(1).test_idx);
  acts = NaN(n_events, 1);
  
  for i=1:length(res)
    iter_res = res(i);
    
    missing = all(isnan(iter_res.acts), 1);
    
    switch stat_type
     case 'acts'
      % get classifier activation for the correct unit
      mat = iter_res.acts(logical(iter_res.targs));
      
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
  missing = all(isnan(acts), 1);
  acts = acts(:,~missing);
  targs = targs(:,~missing);

  if isempty(acts)
    perfmet = struct;
    perf = NaN;
  else
    perfmet = f_perfmet(acts, targs);
    perf = perfmet.perf;
  end
  
