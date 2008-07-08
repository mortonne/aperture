function subj = get_sessdirs(dataroot,subjstr)
%
%GET_SESSDIRS   Generate a subj struct for a given experiment directory.
%   SUBJ = GET_SESSDIRS(DATAROOT,SUBJSTR) looks for directories in
%   DATAROOT that match SUBJSTR (which may contain wildcards), and
%   creates a vector of "subj" structs, each contain a "sess" struct
%   for each session directory that contains a session.log file.
%

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
        
    if exist(fullfile(sessdir, 'session.log'), 'file')
      % if there is a logfile, add a sess struct
      subj(s).sess(n).number = str2num(sessions{n}(end));
      subj(s).sess(n).dir = sessdir;
    end
  end
end
