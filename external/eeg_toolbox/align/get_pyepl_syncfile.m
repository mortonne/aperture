function syncfile = get_pyepl_syncfile(sess_dir, name)
%GET_PYEPL_SYNCFILE   Prepare a pyEPL sync pulse file for alignment.
%
%  syncfile = get_pyepl_syncfile(sess_dir)

if nargin < 2
  name = 'eeg.eeglog';
end

% look for the processed sync file, with UP times only
proc_name = [name '.up'];
syncfile = fullfile(sess_dir, proc_name);

if ~exist(syncfile, 'file')
  % look for a raw sync file
  raw_syncfile = fullfile(sess_dir, name);
  if ~exist(raw_syncfile, 'file')
    error('Behavioral pulse file not found: %s\n', raw_syncfile)
  end
  
  % remove all but the UP times
  fixEEGLog(raw_syncfile, syncfile);
end

