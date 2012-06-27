function init_eeg_ana()
%INIT_EEG_ANA   Add paths necessary to use the EEG Analysis Toolbox.
%
%  init_eeg_ana()

main_dir = fileparts(which('init_eeg_ana'));

% main directories
myaddpath('basic');
myaddpath(fullfile('events', 'creation'));
myaddpath(fullfile('events', 'operations'));
myaddpath(fullfile('events', 'stats'));
myaddpath('patclass');
myaddpath(fullfile('patterns', 'artifacts'));
myaddpath(fullfile('patterns', 'creation'));
myaddpath(fullfile('patterns', 'dimensions'));
myaddpath(fullfile('patterns', 'operations'));
myaddpath(fullfile('plotting', 'figures'));
myaddpath(fullfile('plotting', 'reports'));
myaddpath('resources');
myaddpath('stats');
myaddpath('utils');
myaddpath(fullfile('utils', 'distcomp'));

% external packages
addpath(genpathsafe(fullfile(main_dir, 'external', 'beh_toolbox')));
addpath(genpathsafe(fullfile(main_dir, 'external', 'eeg_toolbox')));
myaddpath(fullfile('external', 'mvpa', 'core', 'learn'))
myaddpath(fullfile('external', 'mvpa', 'core', 'util'))
myaddpath(fullfile('external', 'eeglab', 'functions', 'adminfunc'))
myaddpath(fullfile('external', 'eeglab', 'functions', 'sigprocfunc'))

function myaddpath(p)
  addpath(fullfile(main_dir, p))
end

end
