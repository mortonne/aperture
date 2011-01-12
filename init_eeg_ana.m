function init_eeg_ana()
%INIT_EEG_ANA   Add paths necessary to use the EEG Analysis Toolbox.
%
%  init_eeg_ana()

main_dir = fileparts(which('init_eeg_ana'));

% main directories
myaddpath('basic');
myaddpath('events/creation');
myaddpath('events/operations');
myaddpath('events/stats');
myaddpath('patclass');
myaddpath('patterns/artifacts');
myaddpath('patterns/creation');
myaddpath('patterns/dimensions');
myaddpath('patterns/operations');
myaddpath('plotting/figures');
myaddpath('plotting/reports');
myaddpath('resources');
myaddpath('stats');
myaddpath('utils');

% external packages
addpath(genpathsafe(fullfile(main_dir, 'external', 'beh_toolbox')));
addpath(genpathsafe(fullfile(main_dir, 'external', 'eeg_toolbox')));
myaddpath('external/mvpa/core/learn')
myaddpath('external/mvpa/core/util')

function myaddpath(p)
  addpath(fullfile(main_dir, p))
end

end
