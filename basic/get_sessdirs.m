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
%   the criterion for whether a session should be included.  Set FILE2CHECK
%   to '' to return all session directories, regardless of whether they
%   contain data.
%

if ~exist('file2check','var')
  file2check = 'session.log';
end
if ~exist('subjstr','var')
  subjstr = 'subj*';
end

% get all directories matching subjstr
d = dir(fullfile(dataroot, subjstr));
subjects = {d.name};

for s=1:length(subjects)
  % get the subject path
  subjdir = fullfile(dataroot, subjects{s});

  % initialize this subject
  subj(s).id = subjects{s};
  
  % get all session directories
  d = dir(fullfile(subjdir, 'session_*'));
  sessions = {d.name};
  
  for n=1:length(sessions)
    % get the session path
    sessdir = fullfile(subjdir, sessions{n});
    
    if isempty(file2check) || exist(fullfile(sessdir, file2check), 'file')
      % if there is a logfile, add a sess struct
      subj(s).sess(n).number = str2num(sessions{n}(end));
      subj(s).sess(n).dir = sessdir;
    end
  end
end
