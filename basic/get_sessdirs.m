function subj = get_sessdirs(dataroot,subjstr,file2check)
%
%GET_SESSDIRS   Generate a subj struct for a given experiment directory.
%   SUBJ = GET_SESSDIRS(DATAROOT,SUBJSTR) looks for directories in
%   DATAROOT that match SUBJSTR (which may contain wildcards; default is
%   'subj*'), and creates a vector of "subj" structs, each containing a 
%   "sess" struct for each session directory that contains a session.log
%   file.
%
%   SUBJ = GET_SESSDIRS(DATAROOT,SUBJSTR,FILE2CHECK) uses FILE2CHECK as
%   the criterion for whether a session should be included.  FILE2CHECK
%   is a path to a file relative to each session directory.  It may contain 
%   wildcards, and may either be a string or a cell array of strings.  
%   Set FILE2CHECK to '' to return all session directories, regardless of 
%   whether they contain data.
%
%   Example
%     subj = get_sessdirs(dataroot,'LTP*',{'session.log', 'eeg/*.raw'})
%     gets all subjects in dataroot whose id starts with LTP, and all of
%     their sessions that have both a session log file and an eeg file.
%

if ~exist('file2check','var')
  file2check = {'session.log'};
end
if ~iscell(file2check)
  file2check = {file2check};
end
if ~exist('subjstr','var')
  subjstr = 'subj*';
end

% get all directories matching subjstr
d = dir(fullfile(dataroot, subjstr));
subjects = {d.name};

subj = struct;
for s=1:length(subjects)

  % initialize this subject
  subj(s).id = subjects{s};
  subj(s).dir = fullfile(dataroot, subjects{s});
  
  % get all session directories
  d = dir(fullfile(subj(s).dir, 'session_*'));
  sessions = {d.name};
  
  for n=1:length(sessions)
    % get the session path
    sessdir = fullfile(subj(s).dir, sessions{n});
    
    for i=1:length(file2check)
      % see if the file2check exists for this session
      fileExists(i) = ~isempty(dir(fullfile(sessdir, file2check{i})));
    end
    
    if isempty(file2check) || all(fileExists)
      % if the file(s) exist, add a sess struct
      subj(s).sess(n).number = str2num(sessions{n}(end));
      subj(s).sess(n).dir = sessdir;
    end
  end
end
