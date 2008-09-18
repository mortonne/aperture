function [exp,events] = catallevents(exp,evname,resdir)
%CATALLEVENTS   Concatenate events from all subjects.
%   [EXP,EVENTS] = CATALLEVENTS(EXP,EVNAME,RESDIR)
%   concatenates events from each subject in EXP. Events
%   are loaded from the ev object in each subject named
%   EVNAME (default: 'events').
%
%   The concatenated events are saved in RESDIR/EVNAME.mat.
%   The default RESDIR is exp.resDir.
%

if ~exist('resdir','var')
  resdir = exp.resDir;
end
if ~exist('evname','var')
  evname = 'events';
end

% concatenate events for all subjects
events = getvarallsubj(exp,{'ev',evname},'events');

% create a new ev object to hold overall events
evfile = fullfile(resdir,[evname '.mat']);
ev = init_ev(evname,{exp.subj.id},evfile,length(events));

% save the new events
save(ev.file,'events')
fprintf('Events saved in %s.\n', ev.file)

% update the exp struct
exp = update_exp(exp,'ev',ev);
