function post_process_exp(exp, eventsFcnHandle, overwrite)
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

% write all file info first
for s=1:length(exp.subj)
  for n=1:length(exp.subj(s).sess)
    exp.subj(s).sess(n).eventsFile = fullfile(exp.subj(s).sess(n).dir, 'events.mat');
  end  
end
save(exp.file, 'exp');

% do any necessary post-processing, save events file for each subj
for s=1:length(exp.subj)
  for n=1:length(exp.subj(s).sess)
    
    if overwrite | ~exist(exp.subj(s).sess(n).eventsFile, 'file')
      % create events
      events = eventsFcnHandle(exp.dataroot, exp.subj(s).id, exp.subj(s).sess(n).number);
      save(exp.subj(s).sess(n).eventsFile, 'events');
      
      % post-process
      try
	badchans = textread(fullfile(exp.subj(s).sess(n).dir, 'eeg', 'bad_channels.txt'));
      catch
	fprintf('Warning: error reading bad channel file for %s, session_%d.\n', exp.subj(s).id, exp.subj(s).sess(n).number);
	badchans = [];
      end
	prep_egi_data(exp.subj(s).id, exp.subj(s).sess(n).dir, {'events.mat'}, badchans, 'mstime');
	
    end
  
  end
end
