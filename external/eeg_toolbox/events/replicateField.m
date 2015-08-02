function s = replicateField(s,fieldname,value)
%ADDFIELD - Add/set a field to an events structure with the save value.
%
%
%

% loop over each value
for i = 1:length(s)
  s(i).(deblank(fieldname)) = value;
end