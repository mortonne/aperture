function exp = post_process_exp(exp, eventsFcnHandle, params, varargin)
%
%POST_PROCESS - processes free recall experimental data 
%
% Function does several post processing steps: 
%               1) extracts channel info from .raw file created using Netstation
%               2) creates free recall and recognition events structures
%                  (with word frequency fields)
%               3) aligns eeg with beh data and adds eeg subfields to events structs   
%               4) adds artifactMS field using addArtifacts 
%               5) Average Rerefrences eeg data
%
% FUNCTION:  
%   post_process_catFR(subj, resDir)
%

if ~exist('params', 'var')
  params = struct();
end

params = structDefaults(params, 'overwrite', 0,  'lock', 1,  'ignoreLock', 0);

% write all file info first
for s=1:length(exp.subj)
  for n=1:length(exp.subj(s).sess)
    exp.subj(s).sess(n).eventsFile = fullfile(exp.subj(s).sess(n).dir, 'events.mat');
  end  
end
save(exp.file, 'exp');

event_errs = '';
errs = '';
% do any necessary post-processing, save events file for each subj
for s=1:length(exp.subj)
  subj = exp.subj(s);
  for n=1:length(exp.subj(s).sess)
    sess = exp.subj(s).sess(n);
    
    fprintf('\nCreating event structure for %s, session %d...\n', subj.id, sess.number);
    
    if prepFiles({}, sess.eventsFile, params)==0 % outfile is ok to go
      try
	% create events
	events = eventsFcnHandle(sess.dir, subj.id, sess.number, varargin{:});
	save(sess.eventsFile, 'events');
      catch
	% if problem with events, note and continue to next session
	err = [subj.id ' session_' num2str(sess.number) '\n'];
	event_errs = [event_errs err];
	continue
      end
      
      try
	% read the bad channels file if there is one
	badchans = textread(fullfile(sess.dir, 'eeg', 'bad_channels.txt'));
      catch
	% continue without excluding bad channels from rereferencing
	fprintf('Warning: error reading bad channel file for %s, session_%d.\n', subj.id, sess.number);
	badchans = [];
      end
      
      try
	% split, sync, rereference, detect blink artifacts
	cd(sess.dir);
	prep_egi_data(subj.id, sess.dir, {'events.mat'}, badchans, 'mstime');
      catch
	% if there was an error, remove the events so this session
        % will be processed again next time
	system(['rm ' sess.eventsFile]);
	err = [subj.id ' session_' num2str(sess.number) '\n'];
	errs = [errs err];
      end
    end
    
    % if the eventsfile was locked, release it
    closeFile(sess.eventsFile);
  end
end
if ~isempty(event_errs)
  fprintf(['\nWarning: problems creating events for:\n' event_errs]);
end
if ~isempty(errs)
  fprintf(['\nWarning: problems processing:\n' errs]);
end
