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
%     exp = post_process_exp(exp,@FRevents,{}, 'events.mat', 'eventsOnly',1);
%     makes events for each session in exp using FRevents.m.
%

if ~exist('eventsfile','var')
  eventsfile = 'events.mat';
end

params = struct(varargin{:});

params = structDefaults(params, 'skipError', 1,  'eventsOnly', 0, ...
			'alignOnly', 0, 'splitOnly', 0, 'rerefVariations', 0, ...
			'overwrite', 0, 'lock', 0,  'ignoreLock', 0, ...
			'captype','HCGSN');

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
    if params.splitOnly
      fprintf('Splitting raw files only...\n')
      splitOnly(subj, sess);
      continue
    elseif params.rerefVariations
	fprintf('Performing rereferencing variations...\n')
	rerefVariations(sess, params.captype);      
    end
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

function splitOnly(subject, session)
  % Split the .raw files for a session and exit

  eegdir = fullfile(session.dir, 'eeg')
  norerefdir = fullfile(eegdir, 'eeg.noreref')
  rawfiles = dir(fullfile(eegdir,'*.raw'));
  if length(rawfiles) == 0
    error('No raw eeg file found.');
    return
  end

  for i=1:length(rawfiles)
    % split this file into channels
    basename = egi_split(fullfile(session.dir,'eeg',rawfiles(i).name), ...
			 subject.id, norerefdir);
    
  end

function rerefVariations(session, captype)
  % I am truly sorry that this is such a mess.
  
  % get perif (???) for reref
  [eog,perif] = getcapinfo(captype);
  
  % get events struct for this session and read fileroots off of it
  sess_events = loadEvents(session.eventsFile);
  file_roots = unique(getStructField(sess_events, 'eegfile', ...
						  '~strcmp(eegfile,'''')'));
 
  % build a coordinated structure to store the bad channels as read from files
  bc_types = {'auto', 'spectral', 'manual'};
  bad_chans = struct('auto',[],'spectral',[],'manual',[]);


  % get the bad channels of each type
  for i=1:length(bc_types)
    bc_type = bc_types{i};
    try
      bc_file = fullfile(session.dir, 'eeg', ['bad_chan.txt.' bc_type]);
      bad_channels = textread(bc_file, '', 'commentstyle', 'shell')';	
    catch
      fprintf('Could not read bad channels in %s\n', bc_file);
    end
    % sanity check: bad_channels should be one column!
    if size(bad_channels, 1) ~= 1
      fprintf('Bad file read: %s, channels %s', bc_file, bad_channels)
      error('Multidimensional bad channel data shouldn''t exist!')
    end
    bad_chans.(bc_type) = bad_channels;
  end

  % build a coordinated structure to use to perform the different rerefs
  eegdir = fullfile(session.dir, 'eeg');
  norerefdir = fullfile(eegdir, 'eeg.noreref');
  auto_reref_dir = fullfile(eegdir, 'eeg.reref_auto');
  autospec_reref_dir = fullfile(eegdir, 'eeg.reref_autospectral');
  all_reref_dir = fullfile(eegdir, 'eeg.reref_all');

  rerefs.types = {'auto', 'autospectral', 'all'};
  rerefs.dirs =  {auto_reref_dir, autospec_reref_dir, all_reref_dir};
  rerefs.bad_channels = {bad_chans.auto, [bad_chans.auto bad_chans.spectral], ...
		         [bad_chans.auto bad_chans.spectral bad_chans.manual]};
		         
  % perform the rereference for each variant
  for i=1:length(rerefs.types)
   excluded_channels = unique([rerefs.bad_channels{i}, perif]);
   all_channels = 1:129;
   reref(file_roots, all_channels, rerefs.dirs{i}, ...
	 {all_channels, setdiff(all_channels, excluded_channels)});
  end