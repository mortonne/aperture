function exp = rmobj_allsubj(exp, query, varargin)
%exp = rmobj_allsubj(exp, query, varargin)

for s=1:length(exp.subj)
	fprintf('%s: ', exp.subj(s).id);
  exp = rmobj(exp, query, 'subj', exp.subj(s).id, varargin{:});
end
