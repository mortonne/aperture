function tweak_fig(fig_handle, file, printopt)
%TWEAK_FIG   Make adustments to a figure before printing a final copy.
%
%  Often, the default settings of Matlab's figures are not quite what
%  you want and need some tweaking. To complicate matters, printed
%  figures generally look different than they are in Matlab. This
%  function allows one to iteratively examine printed figures and make
%  changes until the figure is perfect.
%
%  tweak_fig(fig_handle, file, printopt)
%
%  INPUTS:
%  fig_handle:  handle to the figure to print.
%
%        file:  file to print to.
%
%    printopt:  cell array of additional inputs to print to specify
%               options. Default is: {'-depsc'}. This prints the figure
%               as a color EPS file.

if ~exist('printopt', 'var')
  printopt = {'-depsc'};
end

if ~exist(fileparts(file), 'dir')
  mkdir(fileparts(file))
end

% make the figure visible
figure(fig_handle)

while true
  % print so they can look at it
  print(fig_handle, printopt{:}, file);
  fprintf('printed in: %s\n', file)
  
  % what do you want to do next?
  r = input('print/change/quit (p/c/q): ', 's');
  switch r
   case {'print' 'p'}
    % print so they can look at it
    print(fig_handle, printopt{:}, file);
    fprintf('printed in: %s\n', file)
    
   case {'change' 'c'}
    % allow changes
    fprintf('Make changes, then type "return".\n')
    keyboard
    print(fig_handle, printopt{:}, file);
    fprintf('printed in: %s\n', file)
    
   case {'quit' 'q'}
    return
  end
end

