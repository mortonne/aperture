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
    switch get_error_id(err)
     case {'NoMatchStart', 'NoMatchEnd'}
      fprintf('Warning: alignment failed for %s.\n', ...
              sess.dir)
     case 'PulseFileNotFound'
      fprintf('Warning: pulse file not found for %s.\n', ...
              sess.dir)
     case 'NoEEGFile'
      fprintf('Warning: all events out of bounds for %s.\n', ...
              sess.dir)
     case 'CorruptedEEGFile'
      fprintf('Warning: EEG file for %s is corrupted.\n', sess.dir)
     otherwise
      % just print the error output
      warning('eeg_ana:post_process_subj:SessError', ...
              'prep_egi_data2 threw an error for %s:\n %s', ...
              sess.dir, getReport(err))
    end
  end
  
end
