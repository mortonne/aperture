function exp = rmobj_allsubj(exp, varargin)
%
%RMOBJ_ALLSUBJ   Remove a similarly-placed object from all subjects.
%   EXP = RMOBJ_ALLSUBJ(EXP,VARARGIN)
%   
%   Arguments are the same as for RMOBJ, except the path
%   is relative to each subj struct.
%

for s=1:length(exp.subj)
	fprintf('%s\n', exp.subj(s).id);
	
	% delete the object
	exp.subj(s) = recursive_rmfield(exp.subj(s), varargin);
end
fprintf('\n')

% update exp
exp = update_exp(exp);
