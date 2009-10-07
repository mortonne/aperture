function c = create_groups_from_labels(subj, chanfield, group_labels)
% CREATE_GROUPS_FROM_LABELS
%
%
%  INPUTS:
%     chanfield - String specifying the sub-field of the chan
%                 structure that the group labels are trying to match.
%  group_labels - Cell array of strings specifying the label
%                 corresponding to each index group that the
%                 function will output. 
%
%  OUTPUTS:
%             c - Cell array of cells, each sub-cell contains a vector
%                 of indices.  Appropriate to pass this into
%                 apply_by_group. 
%
%  USAGE:
%     chanfield = 'Loc2';
%     group_labels = {'Temporal Lobe', 'Limbic Lobe'};
%     c = create_groups_from_labels(exp.subj(1), chanfield, group_labels);
%

for i = 1:length(group_labels)
  
  c{i} = find(strcmp({subj.chan.(chanfield)}, group_labels{i}));
  
end




