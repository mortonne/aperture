function exp = post_process_exp(exp,eventsFcnHandle,fcnInput,eventsfile,varargin)
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
%     exp = post_process_exp(exp,@FRevents,'eventsOnly',1);
%     makes events for each session in exp using FRevents.m.
%

if ~exist('eventsfile','var')
  eventsfile = 'events.mat';
end

params = struct(varargin{:});

params = structDefaults(params, 'skipError', 1,  'eventsOnly', 0,  'alignOnly', 0,  'overwrite', 0,  'lock', 0,  'ignoreLock', 0, 'captype','HCGSN');

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
for subj=exp.subj
  for sess=subj.sess
    %fprintf('\nCreating event structure for %s, session %d...\n', subj.id, sess.number);

    if prepFiles({}, sess.eventsFile, params)==0 % outfile is ok to go
      fprintf('\n')
      fprintf('%s session %d', subj.id, sess.number)

      % create events
      fprintf('\nCreating events using %s...\n', func2str(eventsFcnHandle))
      events = eventsFcnHandle(sess.dir, subj.id, sess.number, fcnInput{:});
      save(sess.eventsFile, 'events');

      if params.eventsOnly
        closeFile(sess.eventsFile);
        continue
      end

      try
        % read the bad channels file if there is one
        badchans = textread(fullfile(sess.dir, 'eeg', 'bad_chan.txt'))';
      catch
        % continue without excluding bad channels from rereferencing
        fprintf('Warning: error reading bad channel file for %s, session_%d.\n', subj.id, sess.number);
        badchans = [];
      end

      cd(sess.dir);
      if params.alignOnly
        fprintf('Aligning new events...\n')
        alignOnly(sess);
      else
        % split, sync, rereference, detect blink artifacts
        fprintf('Post-processing...\n')
        prep_egi_data(subj.id, sess.dir, {'events.mat'}, badchans, 'mstime', params.captype);
        fprintf('Creating links and moving rereferenced channel files to /data4/scratch/ltp...')
        unix('mvlnltp.sh');
        fprintf('done.\n')
      end

    end

    % if the eventsfile was locked, release it
    closeFile(sess.eventsFile);
  end
end
fprintf('\n')
if ~isempty(event_errs)
  fprintf(['Warning: problems creating events for:\n' event_errs]);
end
if ~isempty(errs)
  fprintf(['Warning: problems processing:\n' errs]);
end


function alignOnly(sess)
  % get the filenames we need
  rerefdir = fullfile(sess.dir, 'eeg', 'eeg.reref');
  norerefdir = fullfile(sess.dir, 'eeg', 'eeg.noreref');
  d = dir(fullfile(rerefdir, '*.001'));
  if isempty(d)
    error('Channel files not found in %s.', rerefdir)
  end
  basename = d.name(1:end-4);

  d2 = dir(fullfile(norerefdir, [basename '.DIN1']));
  if isempty(d)
    error('Pulse files not found in %s.', norerefdir)
  end
  for i=1:length(d2)
    pulse_eeg{i} = fullfile(norerefdir, d2(i).name);
  end

  % behavioral sync pulses, eeg sync pulses, basename
  pulse_beh = {fullfile(sess.dir, 'eeg.eeglog.up')};
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
