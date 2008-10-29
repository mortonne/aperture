function post_process_exp2(exp,varargin)
%POST_PROCESS_EXP   Update the post-processing for each session in exp.
%   EXP = POST_PROCESS_EXP(EXP,EVENTSFCNHANDLE,FCNINPUT,EVENTSFILE) creates 
%   an events struct for each session in EXP using the function specified
%   by EVENTSFCNHANDLE.  The events creation function should take
%   session directory, subject id, session number in that order.
%   Additional arguments can be passed into the function using the
%   optional cell array FCNINPUT.  Events for each session will be saved
%   in sess.dir/EVENTSFILE (default: 'events.mat').
%
%   Unless overwrite is set to true, sessions that already have an
%   events struct will not be processed.
%
%   Options for post-processing can be set using property-value pairs.
%   Options:
%      eventsOnly (0) - create events, without doing post-processing
%      alignOnly (0) - create events and align w/o post-processing
%      skipError (1) - ignore errors, then report them at the end
%      overwrite (0) - overwrite existing files
%      
%   Example:
%     exp = post_process_exp(exp,@FRevents,{}, 'events.mat', 'eventsOnly',1);
%     makes events for each session in exp using FRevents.m.
%

% do any necessary post-processing, save events file for each subj
for subj=exp.subj
  for sess=subj.sess
    % split, sync, rereference, detect blink artifacts
    prep_egi_data2(subj.id,sess.dir,varargin{:});
  end
end
