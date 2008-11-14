function subj = get_sessdirs(dataroot,subjstr,file2check)
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
%   See also init_exp, init_scalp, init_iEEG.
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
    d = dir(fullfile(subj(s).dir{j}, 'session_*'));
    
    sessions = {d.name};
    for n=1:length(sessions)
      % get the session path
      sessdir = fullfile(subj(s).dir{j}, sessions{n});

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
