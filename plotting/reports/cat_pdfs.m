function cat_pdfs(in_files, out_file, varargin)
%CAT_PDFS   Concatenate PDF files together.
%
%  cat_pdfs(in_files, out_file, ...)
%
%  INPUTS:
%  in_files:  cell array of paths to input PDF files.
%
%  out_file:  path to the new PDF to create.
%
%  PARAMS:
%  paper   - paper type. See texexec for details. ('landscape')
%  verbose - print output from texexec. (false)
%
%  NOTES:
%   texexec and kpsewhich must be on your UNIX path. User getenv('PATH')
%   to check your path within MATLAB.

% Copyright 2007-2011 Neal Morton, Sean Polyn, Zachary Cohen, Matthew Mollison.
%
% This file is part of EEG Analysis Toolbox.
%
% EEG Analysis Toolbox is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% EEG Analysis Toolbox is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser General Public License
% along with EEG Analysis Toolbox.  If not, see <http://www.gnu.org/licenses/>.

defaults.paper = 'landscape';
defaults.verbose = false;
params = propval(varargin, defaults);

% % find texexec
% locs = {'texexec', '/sw2/bin/texexec'};
% program = '';
% for i=1:length(locs)
%   [s, out] = unix(['which ' locs{i}]);
%   if ~isempty(out)
%     % found it
%     program = locs{i};
%     break
%   end
% end

% if isempty(program)
%   error('could not find texexec.')
% end

% construct the command
program = 'texexec';
in_str = sprintf('%s ', in_files{:});
options = sprintf('--paper=%s --pdfcombine --combination=1*1', ...
                  params.paper);
command = sprintf('%s %s --result %s %s', ...
                  program, options, out_file, in_str);

% call and display output
[s, out] = unix(command);

if params.verbose
  disp(out)
end

