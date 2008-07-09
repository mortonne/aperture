function exp = init_exp(subj, resDir, experiment, recordingType, useLock)
%
%INIT_EXP   Initialize an exp struct.
%   EXP = INIT_EXP(SUBJ,RESDIR,EXPERIMENT,RECORDINGTYPE,USELOCK) creates an
%   exp struct EXP containing subjects in the SUBJ struct and saves it in
%   RESDIR.  The lastUpdate field will be initialized to the time of creation.
%
%   Optional inputs:
%     EXPERIMENT - name of the experiment
%     RECORDINGTYPE - if brain data was collected, which type was it 
%     USELOCK - specifies whether the exp struct needs to be locked before
%               updates (default 0)
%

if ~exist('experiment','var')
  experiment = '';
end
if ~exist('recordingType','var')
  recordingType = 'N/A';
end
if ~exist('useLock','var')
  useLock = 0;
end

if ~exist(resDir)
  mkdir(resDir);
end

% create the struct
exp = struct('experiment', experiment, 'recordingType', recordingType, 'subj', subj, 'resDir', resDir, 'file', fullfile(resDir, 'exp.mat'), 'useLock', useLock);  

% write the creation time
exp.lastUpdate = datestr(now, 'ddmmmyy_HHMM');

% save the new exp struct
save(fullfile(exp.resDir, 'exp.mat'), 'exp');
