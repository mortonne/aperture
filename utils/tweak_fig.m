function tweak_fig(fig_handle, file, printopt)
%TWEAK_FIG   Make adustments to a figure before printing a final copy.
%
%  tweak_fig(fig_handle, file, printopt)

if ~exist('printopt', 'var')
  printopt = {'-depsc'};
end

% make the figure visible
figure(fig_handle)

while true
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

