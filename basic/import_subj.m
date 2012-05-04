function subj = import_subj(subj_file, varargin)
%IMPORT_SUBJ   Import information about a subject.
%
%  subj = import_subj(subj_file, ...)
%
%  Currently only supports reading in from YAML files of a specific
%  format. Later may expand to import from other formats,
%  especially from other MATLAB EEG toolboxes.

def.tasks = {};
def.subj_fields = {'id' 'age' 'gender'};
def.sess_fields = {'task' 'number' 'start' 'finish' 'testers' 'sync' ...
                   'notes'};
def.repstr = {};
opt = propval(varargin, def);
if ischar(opt.tasks)
  opt.tasks = {opt.tasks};
end

% read in the YAML file
s = ReadYaml(subj_file);

% copy over relevant fields
subj = copy_field(s, struct, opt.subj_fields);

% format the sessions properly
subj.sess = [];
for i = 1:length(s.session)
  if ~isempty(opt.tasks)
    if ~ismember(s.session{i}.task, opt.tasks)
      continue
    end
  end
  sess = copy_field(s.session{i}, struct, opt.sess_fields);
  sess.dir = s.session{i}.behavior;
  sess.eegfile = s.session{i}.eeg;
  if ~isempty(opt.repstr)
    sess = struct_strrep(sess, opt.repstr{:});
  end
  
  if ~isempty(sess.dir) && ~exist(sess.dir, 'dir')
    warning('Behavioral session directory does not exist: %s', sess.dir)
  end
  if ~isempty(sess.eegfile) && ~exist(sess.eegfile, 'file')
    warning('EEG data file does not exist: %s', sess.eegfile)
  end
  subj.sess = addobj(subj.sess, sess);
end

if ~isempty(opt.repstr)
  subj = struct_strrep(subj, opt.repstr{:});
end

