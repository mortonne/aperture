function exp = post_process_exp(exp, eventsFcnHandle, params, eventsfile, varargin)
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
%   exp = post_process_exp(exp, eventsFcnHandle, params, varargin)
%

if ~exist('eventsfile','var')
	eventsfile = 'events.mat';
end
if ~exist('params','var')
	params = struct();
end

params = structDefaults(params, 'skipError', 1,  'eventsOnly', 0,  'alignOnly', 0,  'overwrite', 0,  'lock', 0,  'ignoreLock', 0);

% write all file info first
for s=1:length(exp.subj)
	for n=1:length(exp.subj(s).sess)
		exp.subj(s).sess(n).eventsFile = fullfile(exp.subj(s).sess(n).dir, eventsfile);
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
				if params.skipError
					% if problem with events, note and continue to next session
					err = [subj.id ' session_' num2str(sess.number) '\n'];
					event_errs = [event_errs err];
					continue
					else
					rethrow(lasterror);
				end
			end

			if params.eventsOnly
				closeFile(sess.eventsFile);
				continue
			end

			try
				% read the bad channels file if there is one
				badchans = textread(fullfile(sess.dir, 'eeg', 'bad_chan.txt'));
				catch
				% continue without excluding bad channels from rereferencing
				fprintf('Warning: error reading bad channel file for %s, session_%d.\n', subj.id, sess.number);
				badchans = [];
			end

			cd(sess.dir);
			try
				if params.alignOnly
					alignOnly(sess);
					else
					% split, sync, rereference, detect blink artifacts
					prep_egi_data(subj.id, sess.dir, {'events.mat'}, badchans, 'mstime');
				end
				catch
				if params.skipError
					% if there was an error, remove the events so this session
					% will be processed again next time
					system(['rm ' sess.eventsFile]);
					err = [subj.id ' session_' num2str(sess.number) '\n'];
					errs = [errs err];
					else
					rethrow(lasterror);
				end
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


function alignOnly(sess)
	% get the filenames we need
	rerefdir = fullfile(sess.dir, 'eeg', 'eeg.reref');
	norerefdir = fullfile(sess.dir, 'eeg', 'eeg.noreref');
	d = dir(fullfile(rerefdir, '*.001'));
	basename = d.name(1:end-4);

	% behavioral sync pulses, eeg sync pulses, basename
	pulse_beh = {fullfile(sess.dir, 'eeg.eeglog.up')};
	pulse_eeg = {fullfile(norerefdir, [basename '.DIN1'])};
	chan_file = {fullfile(rerefdir, d.name)};

  if prepFiles({sess.eventsFile, pulse_beh{1}, pulse_eeg{1}, chan_file{1}})~=0
    error('Input files are missing.')
  end

	% get the samplerate
	[samplerate,nBytes,dataformat,gain] = GetRateAndFormat(norerefdir);

	% run the alignment
	runAlign(samplerate,pulse_beh,pulse_eeg,chan_file,{sess.eventsFile},'mstime',0,1)

	% add artifact info
	[eog, perif] = getcapinfo();
	addArtifacts(sess.eventsFile, eog, 100);
