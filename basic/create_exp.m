function exp = create_exp(experiment, res_dir, subj_ids, varargin)
%CREATE_EXP   Create standard experiment struct.
%
%  exp = create_exp(experiment, res_dir, subj_ids, ...)
%
%  INPUTS:
%  experiment:  string identifier for the experiment.
%
%     res_dir:  path to directory to save experiment struct and 
%               analyses.
%
%    subj_ids:  cell array of subject identifiers.
%
%  Additional inputs will be passed to init_exp.
%
%  OUTPUTS:
%      exp:  experiment struct.
%
%  EXAMPLE:
%   subj_ids = {'subj01' 'subj02' 'subj04'};
%   exp = create_exp('mystudy', '~/mystudy_results_dir', subj_ids);

subj = [];
for i = 1:length(subj_ids)
  subj = addobj(subj, init_subj(subj_ids{i}));
end

exp = init_exp(experiment, 'resDir', res_dir, 'subj', subj, varargin{:});
