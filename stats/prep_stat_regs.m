function [group, levels] = prep_stat_regs(events, reg_defs, level_order)
%PREP_STAT_REGS   Prepare regressors for a statistical test.
%
%  [group, levels] = prep_stat_regs(events, reg_defs, level_order)
%
%  INPUTS:
%       events:  events structure.
%
%     reg_defs:  cell array of regressor definitions. See
%                make_event_index for allowed formats.
%
%  level_order:  (optional) cell array of cell arrays of strings, giving
%                the order to label each level within each factor. If a
%                cell is empty, the corresponding labels will be sorted
%                based on how they are output from make_event_index.
%
%  OUTPUTS:
%        group:  cell array of numeric vectors labeling each condition.
%
%       levels:  cell array of cell arrays giving a label for each
%                level of each factor.
%
%  See also make_event_index for making individual regressors.

n_group = length(reg_defs);
group = cell(1, n_group);
levels = cell(1, n_group);
for i = 1:n_group
  [group{i}, levels{i}] = make_event_index(events, reg_defs{i}, ...
                                           level_order{i});
end

