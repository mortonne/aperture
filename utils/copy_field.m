function s = copy_field(s1, s2, fields)
%COPY_FIELD   Copy a field from one structure to another.
%
%  Checks if the field(s) exist on s1, and copies them to s2 if
%  they exist.
%
%  s = copy_field(s1, s2, fields)

if ischar(fields)
  fields = {fields};
end

for i = 1:length(fields)
  if isfield(s1, fields{i})
    s2.(fields{i}) = s1.(fields{i});
  end
end

s = s2;

