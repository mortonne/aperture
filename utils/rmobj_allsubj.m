function exp = rmobj_allsubj(exp, varargin)
%
%RMOBJ_ALLSUBJ   Remove a similarly-placed object from all subjects.
%   EXP = RMOBJ_ALLSUBJ(EXP,VARARGIN)
%   
%   Arguments are the same as for RMOBJ, except the path
%   is relative to each subj struct.
%

for subj=exp.subj
	fprintf('%s: ', subj.id);
	
	% delete the object
	exp = recursive_rmfield(exp, 'subj', subj.id, varargin{:});
end

% update exp
exp = update_exp(exp);
