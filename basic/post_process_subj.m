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
  try
    % split, sync, rereference, detect blink artifacts
    prep_egi_data2(subj.id,sess.dir,varargin{:});
  catch err
    warning('eeg_ana:post_process_subj:SessError', ...
            'prep_egi_data2 threw an error for %s session %d:\n %s', ...
            subj.id, sess.number, getReport(err))
  end
end
