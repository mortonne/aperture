function exp = init_exp(subj, resDir, experiment, recordingType, useLock)
%
%INIT_EXP
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
