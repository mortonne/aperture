function subj = post_process_subj(subj,varargin)
%POST_PROCESS_SUBJ   Update the post-processing for one subject.
%
%  subj = post_process_subj(subj, varargin)
%
%  INPUTS:
%      subj:  standard subj structure representing one subject.
%
%  varargin:  additional inputs (after subj.id and sess.dir)
%             to prep_egi_data2.

% do any necessary post-processing, save events file for each subj
for sess=subj.sess
  % split, sync, rereference, detect blink artifacts
  prep_egi_data2(subj.id,sess.dir,varargin{:});
end
