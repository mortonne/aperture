function pat = pattern_seg2cont(pat, varargin)
%PATTERN_SEG2CONT   Convert a segmented pattern to continuous form.
%
%  pat = pattern_seg2cont(pat, ...)
%
%  INPUTS:
%      pat:  input pattern object.
%
%  OUTPUTS:
%      pat:  pattern reshaped to be continuous. Events have an added
%            "time" field giving the time of each event.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   dim_names      - ({'time'})
%   save_mats      - if true, and input mats are saved on disk, modified
%                    mats will be saved to disk. If false, the modified
%                    mats will be stored in the workspace, and can
%                    subsequently be moved to disk using move_obj_to_hd.
%                    (true)
%   overwrite      - if true, existing patterns on disk will be
%                    overwritten. (false)
%   save_as        - string identifier to name the modified pattern. If
%                    empty, the name will not change. ('')
%   res_dir        - directory in which to save the modified pattern and
%                    events, if applicable. Default is a directory named
%                    pat_name on the same level as the input pat.

% input checks
if ~exist('pat', 'var') || ~isstruct(pat)
  error('You must input a pattern object.')
end

% options
defaults.dim_names = {'time'};
[params, saveopts] = propval(varargin, defaults);

% run seg2cont
pat = mod_pattern(pat, @run_seg2cont, {params}, saveopts);

function pat = run_seg2cont(pat, params)

  % load the pattern
  pattern = get_mat(pat);
  events = get_dim(pat.dim, 'ev');
  
  % reshape to merge dimension with events
  dims = 1:4;
  
  for i = 1:length(params.dim_names)
    % move this dim to the front
    pat_size = patsize(pat.dim);
    [dim_name, dim_number] = read_dim_input(params.dim_names{i});
    dim_size = pat_size(dim_number);
    new_order = [dim_number dims(~ismember(dims, dim_number))];
    
    % reshape
    new_shape = [pat_size(1) * dim_size ...
                 pat_size(~ismember(dims, [1 dim_number]))];
    pattern = reshape(permute(pattern, new_order), new_shape);
    
    % create new events with a field for this dim
    dim_vals = get_dim_vals(pat.dim, dim_name);
    
    new_events = [];
    vals_cell = num2cell(dim_vals);
    for j = 1:pat_size(1)
      these_events = repmat(events(j), 1, dim_size);
      [these_events.(dim_name)] = vals_cell{:};
      new_events = [new_events these_events];
    end
    events = new_events;
    
    % collapse the dim
    switch dim_name
     case 'chan'
      new_dim = struct('number', [], 'label', '');
     case 'time'
      new_dim = init_time();
     case 'freq'
      new_dim = init_freq();
    end
    pat.dim = set_dim(pat.dim, dim_name, new_dim, 'ws');
  end

  % store the new pattern and events
  pat = set_mat(pat, pattern, 'ws');
  pat.dim = set_dim(pat.dim, 'ev', events, 'ws');
  
