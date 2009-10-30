function subj = classify_pat2pat_sweep(subj, train_pat_name, ...
                                       test_pat_name, stat_name, ...
				       res_dir, params)
% CLASSIFY_PAT2PAT_SWEEP
%
% INPUTS:
%    subj - a subject object
%
%    train_pat_name - the name of a training pattern, attached to
%                     the subject object.
%
%    test_pat_name - the name of a test pattern, attached to the
%                    subject object.  These two patterns must have
%                    matching channel and frequency (if it exists)
%                    dimensions.  
%                    
%    stat_name - where to attach the results, will be attached to
%                the pat object.
%
%    res_dir - where to save the output of this function
%
%    params - fields include:
%             iter_cell - controls the slicing.  See docstring for
%                         apply_by_group. 
%             sweep_cell - controls the sweeping (only applied to
%                          test_pattern).  See docstring for
%                          apply_by_group. 
%             penalty
%             f_perfmet
%             perfmet_args
%
%
%

% get the pat objects
train_pat = getobj(subj, 'pat', train_pat_name);
test_pat = getobj(subj, 'pat', test_pat_name);

% grab the events
train_events = get_mat(train_pat.dim.ev);
test_events = get_mat(test_pat.dim.ev);

% the correct answers for classification
train_targs = create_targets(train_events, 'category');
test_targs = create_targets(test_events, 'category');

% load the patterns themselves
train_pattern = get_mat(train_pat);
test_pattern = get_mat(test_pat);

def.penalty = 10;
def.f_perfmet = @perfmet_perm;
def.perfmet_args{1} = {'scramble_type', 'targs'};
% default is to slice over frequency dimension
def.iter_cell = {{},{},{},{'iter'}};
% default is no sweeping
def.sweep_cell = {{},{},{},{}};

params = combineStructs(params, def);

% the outer level of slicing
res.iterations = apply_by_group(@sweep_wrapper, ...
                                {train_pattern, test_pattern}, ...
                                params.iter_cell, ...
                                {train_targs, test_targs}, ...
                                'uniform_output', false);

% handle the output
res.iterations = reshape([res.iterations{:}], size(res.iterations));

% where to save the results
% res_dir = get_pat_dir(train_pat, 'patclass');
filename = sprintf('%s_%s_%s.mat', ...
                   train_pat.name, stat_name, train_pat.source);
stat_file = fullfile(res_dir, filename);
stat = init_stat(stat_name, stat_file, train_pat.name);
% one can save extra information in params, like the set of
% groupnames that were used to make a set of channel groups.
stat.params = params;

% save the results to disk
save(stat.file, 'res');

% add the stat object to the output pat object
subj = setobj(subj, 'pat', train_pat);


function res = sweep_wrapper(train_pattern, test_pattern, ...
                             train_targs, test_targs, params);
% SWEEP_WRAPPER
%
%

% the inner level of sweeping
res = apply_by_group(@traintest, {test_pattern}, ...
                     params.sweep_cell, ...
                     {train_pattern, test_targs, train_targs, params}, ...
                     'uniform_output', false);

