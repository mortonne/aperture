function subj = apply_to_stat(subj, obj_path, fcn_handle, ...
                              fcn_inputs,dist)
%APPLY_TO_STAT   Apply a function to a stat object for all subjects.
%
%  subj = apply_to_stat(subj, obj_path, fcn_handle, 
%                       fcn_inputs, dist)
%  
%  INPUTS:
%        subj:  a [1 X N subjects] structure representing each subject
%               in an experiment.
%
%    obj_path:  cell array of [obj_type, obj_name] pairs giving the
%               address of the stat object in each subject.
%
%  fcn_handle:  a handle for a function that takes a stat object as
%               first input, and outputs a stat object.
%
%  fcn_inputs:  a cell array of additional inputs (after stat) to
%               fcn_handle.
%
%        dist:  if true, subjects will be evaluated in distributed
%               tasks. Default: false
%
%  OUTPUTS:
%        subj:  a modified subjects vector.

% input checks
if ~exist('subj','var')
  error('You must pass a subjects vector.')
elseif ~exist('obj_path', 'var')
  error('You give the path to a stat object.')
elseif ~exist('fcn_handle','var')
  error('You must pass a handle to a function.')
end
if ~exist('fcn_inputs','var')
  fcn_inputs = {};
end
if ~exist('dist','var')
  dist = false;
end

% run the function on each subject
% export stat objects first, so there is less to send to each worker
stats = getobjallsubj(subj, obj_path);

% name will not be unique, but index will
stat_name = obj_path{end-1};
temp_name = cellfun(@num2str, num2cell(1:length(stats)), 'UniformOutput', false);
[stats.name] = deal(temp_name{:});

% run as though the stat objects were subj objects
stats = apply_to_subj(stats, fcn_handle, fcn_inputs, dist);

% fix the name field
[stats.name] = deal(stat_name);

% put the updated stat objects back on the subjects
for i=1:length(subj)
  subj(i) = setobj(subj(i), obj_path{1:end-1}, stats(i));
end

