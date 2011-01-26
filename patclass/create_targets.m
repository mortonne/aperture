function targets = create_targets(events, bin_defs)
%CREATE_TARGETS   Create a conditions matrix from an events structure.
%
%  targets = create_targets(events, bin_defs)
%
%  INPUTS:
%    events:  an events structure.
%
%  bin_defs:  input to make_event_index. Each unique label will
%             correspond to a column of targets.
%
%  OUTPUTS:
%   targets:  [events X conditions] logical array. Each event is assumed
%             to only have one active condition. The active condition
%             for event i is indicated by the true element of
%             targets(i,:).
%
%  NOTES:  To make a version where one can specify a continuous
%   valued field from events.  Requires that each event has a
%   vector [1x nConds] with the values for each cond for that event.
%
%  EXAMPLE:
%   % create an events structure with a field to use for creating a
%   % targets matrix
%   events = struct('x', num2cell([repmat(1,1,4) repmat(2,1,7)]));
%
%   % create a conditions matrix using the field
%   targets = create_targets(events, 'x');
%
%  See also make_event_index.

% input checks
if ~exist('events', 'var') || ~isstruct(events)
  error('You must pass an events structure.')
elseif ~exist('bin_defs', 'var')
  error('You must pass bin definitions.')
end

% create the regressors
targ_vec = make_event_index(events, bin_defs);

% unique condition labels
conds = nanunique(targ_vec);

% create logical conditions matrix
targets = false(length(events), length(conds));
for i = 1:length(conds)
  targets(:,i) = targ_vec == conds(i);
end

