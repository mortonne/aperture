function subj = get_sessdirs(dataroot,subjstr,file2check,sesspath)
%GET_SESSDIRS   Generate a subj struct for a given experiment directory.
%
%  subj = get_sessdirs(dataroot, subjstr, file2check, sesspath)
%
%  This function makes a few simplifying assumptions. Each subject's
%  data is assumed to be in a separate directory, which is named with
%  the subject's identifier. All subject IDs and the names of the
%  session directories must follow a pattern that can be specified using
%  the wildcard characters that Matlab recognizes.
%
%  INPUTS:
%    dataroot:  path to the directory that contains subject directories.
%
%     subjstr:  string that all subject identifiers must match to be
%               included in the subject structure. May contain wildcards.
%               Default: '*'.
%
%  file2check:  cell array of paths, relative to each session directory,
%               to files that must exist for a given session to be
%               included. Set to {} (default) to return all
%               session directories, regardless of whether they contain
%               data.
%
%    sesspath:  path, relative to each subject's directory, to the
%               session directories. May contain wildcards (*).
%
%  OUTPUTS:
%        subj:  a subject structure, formatted for use in eeg_ana
%               functions.
%
%  EXAMPLE:   
%   dataroot = '/data/eeg/scalp/ltp/apem_e7_ltp';
%   subjstr = 'LTP*';
%
%   % include sessions if they have behavioral and EEG data
%   files2check = {'session.log', 'eeg/*.raw*'};
%
%   % get all session of taskFR LTP that have been run so far
%   subj = get_sessdirs(dataroot, subjstr, files2check);
%
%  See also init_exp, init_scalp, init_iEEG.

% input checks
if ~exist('dataroot','var') || ~ischar(dataroot)
  error('You must pass a string indicating the path to the dataroot.')
elseif ~exist(dataroot,'dir')
  error('dataroot does not exist: %s', dataroot)
end
if ~exist('subjstr','var')
  subjstr = '*';
end
if ~exist('file2check','var')
  file2check = {};
end
if ~iscell(file2check)
  file2check = {file2check};
end
if ~exist('sesspath','var')
  sesspath = 'session_*';
end

% get all directories matching subjstr
path_or_wildcard = fullfile(dataroot, subjstr);
if exist(path_or_wildcard, 'dir')
  % subjstr contained a complete directory name inside dataroot, and not a
  % wildcard; therefore, the only subject id is subjstr
  subjects = {subjstr};
else
  % subjstr contained a wildcard (or is an otherwise invalid
  % directory name), so calling dir will return a
  % struct array with matching directory names in the 'name' field
  d = dir(path_or_wildcard);
  subjects = {d.name};
end

subj = [];
todelete = [];
toskip = {};
s = 1;
for i=1:length(subjects)
  if ismember(subjects{i},toskip)
    continue
  end
  
  % find all subjects that contain this subject id string
  match = find(strfound(subjects,subjects{i}));
  
  % get cell array of all ids
  subject = subjects(match);
  if length(subject)>1
    % each sub-subject gets counted once
    toskip = [toskip subject(2:end)];
  end
  
  % use the shortest id
  subj(s).id = subject{1};
  
  subj(s).sess = [];
  for j=1:length(subject)
    % get the directory for this subset of the subject
    subj(s).dir{j} = fullfile(dataroot, subject{j});
    d = dir(fullfile(subj(s).dir{j}, sesspath));
    
    sessions = {d.name};
    for n=1:length(sessions)
      % get the session path
      sessdir = fullfile(subj(s).dir{j}, fileparts(sesspath), sessions{n});

      for f=1:length(file2check)
        % see if the file2check exists for this session
        fileExists(f) = ~isempty(dir(fullfile(sessdir, file2check{f})));
      end

      if isempty(file2check) || all(fileExists)
        % if the file(s) exist, add a sess struct
        if j>1 & length(subj(s).sess)>1
          % multiple sub-subjects; add one to the last session
          % will not match the session directory in this case
          sess.number = subj(s).sess(end).number+1;
          else
          sess.number = str2num(sessions{n}(end));
        end
        sess.dir = sessdir;
        subj(s).sess = [subj(s).sess sess];
      end
    end
  end
  
  if isempty(subj(s).sess)
    todelete(end+1) = s;
  end
  
  s = s + 1;
end

subj(todelete) = [];
