function subj = init_subj(id, varargin)
%INIT_SUBJ   Initialize a subject.
%
%  subj = init_subj(id, ...)
%
%  INPUTS:
%      id:  string identifier for the subject.
%
%  OUTPUTS:
%     subj:  subject struct.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   subj_dir     - path to the subject's data. ('')
%   sess_dirs    - cell array of paths to session data. ({})
%   sess_numbers - numeric array of numbers for each session.
%                  (1:length(params.sess_dirs))
%   eeg_files    - cell array of paths to the EEG files associated with
%                  each session (assumed to be one EEG file per
%                  session). ({})
%
%  See also: get_sessdirs, init_exp.

% options
defaults.subj_dir = '';
defaults.sess_dirs = {};
defaults.sess_numbers = [];
defaults.eeg_files = {};
params = propval(varargin, defaults);

% default session numbers
if isempty(params.sess_numbers)
  if ~isempty(params.sess_dirs)
    n_sess = length(params.sess_dirs);
  elseif ~isempty(params.eeg_files)
    n_sess = length(params.eeg_files);
  else
    n_sess = NaN;
  end
  if ~isnan(n_sess)
    params.sess_numbers = 1:n_sess;
  end
end

% fix input formatting
if iscolumn(params.sess_numbers)
  params.sess_numbers = params.sess_numbers';
end
if iscolumn(params.sess_dirs)
  params.sess_dirs = params.sess_dirs';
end
if iscolumn(params.eeg_files)
  params.eeg_files = params.eeg_files';
end

% get inputs in the right format for struct
if isnumeric(params.sess_numbers)
  params.sess_numbers = num2cell(params.sess_numbers);
end
if isempty(params.sess_numbers)
  params.sess_numbers = {[]};
end
if isempty(params.sess_dirs)
  params.sess_dirs = {''};
end
if isempty(params.eeg_files)
  params.eeg_files = {''};
end

% construct the session sub-struct
sess = struct('number', params.sess_numbers, ...
              'dir', params.sess_dirs, ...
              'eegfile', params.eeg_files);

% construct a subject object
subj = struct('id', id, 'dir', params.subj_dir, 'sess', sess);

