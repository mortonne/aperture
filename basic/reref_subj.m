function subj = reref_subj(subj)
%REREF_SUBJ   Average rereference a subject's EEG.
%
%  Convenience function for running referencing of ECoG data. Only works
%  for data saved in the standard Kahana lab directory structure.
%
%  subj = reref_subj(subj)

wd = pwd;

for sess = subj.sess
  if ~isfield(sess, 'eegfile') || isempty(sess.eegfile)
    error('EEG file is undefined for %s session %d', subj.id, sess.number);
  end
  fileroots = {strrep(sess.eegfile, 'eeg.reref', 'eeg.noreref')};
  
  % get electrode number ranges for each grid
  grid_file = fullfile(subj.dir, 'docs', 'electrodes.m');
  if ~exist(grid_file, 'file')
    error('Grid definitions file does not exist')
  end
  
  % should be an electrodes.m file; this will define a variable r
  % change to the directory to put the script on the path
  cd(fullfile(subj.dir, 'docs')); 
  electrodes
  if ~exist('r', 'var')
    error('%s must define a variable named r', grid_file)
  end
  grids = r;
  
  % set the output directory
  out_dir = fullfile(subj.dir, 'eeg.reref');
  
  % get good leads information
  tal_dir = fullfile(subj.dir, 'tal');
  leads_file = fullfile(tal_dir, 'leads.txt');
  good_leads_file = fullfile(tal_dir, 'good_leads.txt');
  if ~exist(leads_file, 'file')
    error('leads file does not exist')
  end
  if ~exist(good_leads_file, 'file')
    error('good leads file does not exist')
  end

  % run the rereferencing
  reref_trunk(fileroots, grids, out_dir, tal_dir);
end

cd(wd)

