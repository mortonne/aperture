function exp = rmobj_allsubj(exp, query, varargin)
%exp = rmobj_allsubj(exp, query, varargin)

for s=1:length(exp.subj)
  exp = rmobj(exp, query, 'subj', exp.subj(s).id, varargin{:});
end
