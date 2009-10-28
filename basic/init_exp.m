function exp = init_exp(experiment, varargin)
%INIT_EXP   Initialize an exp structure.
%
%  exp = init_exp(experiment, ...)
%
%  Create an experiment structure that can be used to keep track of 
%  analyses.
%
%  INPUTS:
%  experiment:  string identifier for the experiment.
%
%  OUTPUTS:
%      exp:  an experiment object with the following optional fields,
%            which can be set by passing in parameter, value pairs
%            as additional arguments:
%
%             subj          - vector of subject objects. See get_sessdirs.
%             recordingType - the type of brain data collected
%             resDir        - directory where results will be saved
%             file          - path to the MAT-file where this exp
%                             structure will be saved
%             useLock       - if true, exp.file will be locked during
%                             loading and saving. Useful for running
%                             distributed jobs that modify exp
%
%  EXAMPLE:
%   % import information about subjects
%   subj = get_sessdirs(dataroot, 'subj*');
%
%   % create a new exp structure
%   exp = init_exp('catFR', 'subj', subj, 'recordingType', 'scalp');

% input checks
if ~exist('experiment','var')
  error('You must specify an experiment name.')
end

% set defaults
def = struct('experiment',    experiment, ...
             'recordingType', '',         ...
             'subj',          struct,     ...
             'resDir',        '',         ...
             'file',          '',         ...
             'useLock',       false,      ...
             'lastUpdate',    '');

try
  in = struct(varargin{:});
catch err
  % not parameter, value pairs--must be using the old calling signature
  old_args = {'subj', 'resDir', 'experiment', 'recordingType', 'useLock'};
  pairs = {};
  varargin = {experiment, varargin{:}};
  for i=1:length(varargin)
    pairs{end+1} = old_args{i};
    pairs{end+1} = varargin{i};
  end
  in = struct(pairs{:});
end

exp = combineStructs(in, def);
exp = orderfields(exp, def);

% sanity checks
if ~ischar(exp.experiment)
  error('experiment must be a string.')
elseif ~ischar(exp.recordingType)
  error('recordingType must be a string.')
elseif ~isstruct(exp.subj)
  error('subj must be a structure.')
elseif ~ischar(exp.resDir)
  error('resDir must be a string.')
elseif ~islogical(exp.useLock)
  error('useLock must be a logical.')
end

% make sure the results directory exists and define exp.file
if ~isempty(exp.resDir)
  if ~exist(exp.resDir, 'dir')
    mkdir(exp.resDir);
  end
  exp.file = fullfile(exp.resDir, 'exp.mat');
end
