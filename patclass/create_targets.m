function targets = create_targets(events, reg_name)
% CREATE_TARGETS
%   Makes a logical matrix out of an events structure and an events
%   field. 
%
%
%   OUTPUT:
%      targets - [nEv x nConds] where nEv is the number of events
%      in the events structure, and nConds is the number of unique
%      elements that appear in the specified reg_name field.  When
%      a given event is of a particular condition, the
%      corresponding row of targets contains a 1.
%
%   NOTES:  To make a version where one can specify a continuous
%   valued field from events.  Requires that each event has a
%   vector [1x nConds] with the values for each cond for that event.


% create the regressors
targ_vec = make_event_bins(events, reg_name);
conds = unique(targ_vec(~isnan(targ_vec)));
targets = zeros(length(events), length(conds));
for i=1:length(conds)
  cond_match = targ_vec == conds(i);
  targets(:, i) = cond_match;
end




