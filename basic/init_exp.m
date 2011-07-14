function exp = init_exp(varargin)
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
%             subj          - vector of subject objects
%             recordingType - the type of brain data collected
%             resDir        - directory where results will be saved
%             file          - path to the MAT-file where this exp
%                             structure will be saved.  If not
%                             specified, this will default to
%                             resDir/exp.mat.
%
%  EXAMPLE:
%   % import information about subjects
%   subj = get_sessdirs(dataroot, 'subj*');
%
%   % create a new exp structure
%   exp = init_exp('catFR', 'subj', subj, 'recordingType', 'scalp');
%
%  See also init_subj, get_sessdirs.

% options
defaults.experiment = '';
defaults.recordingType = '';
defaults.subj = struct;
defaults.resDir = '';
defaults.file = '';
defaults.useLock = false;
defaults.lastUpdate = '';
old_args = {'subj', 'resDir', 'experiment', 'recordingType', 'useLock'};
old_classes = {'struct' 'char' 'char' 'char' {'logical' 'numeric'}};
init_fields = {'experiment'};
init_classes = {'char'};
exp = list2propval(varargin, defaults, ...
                   'fields', old_args, 'classes', old_classes, ...
                   'init_fields', init_fields, 'init_classes', init_classes);

exp = rmfield(exp, 'useLock');

% sanity checks
if ~ischar(exp.experiment)
  error('experiment must be a string.')
elseif ~ischar(exp.recordingType)
  error('recordingType must be a string.')
elseif ~isstruct(exp.subj)
  error('subj must be a structure.')
elseif ~ischar(exp.resDir)
  error('resDir must be a string.')
end

% define exp.file
if ~isempty(exp.resDir)
  exp.file = fullfile(exp.resDir, 'exp.mat');
end
