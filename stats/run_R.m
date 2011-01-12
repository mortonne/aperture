function output = run_R(r_script, varargin)
%RUN_R   Run an R script and capture the output as text.
%
%  output = run_R(r_script, ...)
%
%  INPUTS:
%  r_script:  string name of the R script to run. Must be somewhere on
%             the MATLAB path.
%
%  OUTPUTS:
%    output:  text output from the R script.

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

if ~(ismac || isunix)
  warning('Designed for UNIX or Mac; may fail for Windows.')
end

% add user library location (hard-coded). Better solution to come.
% in the meantime, user must have a local library in ~/R
% or have necessary packages installed globally
setenv('R_LIBS_USER', '~/R')

% find the full path to the script
r_file = which(r_script);

% create the command
inputs = sprintf('%s ', varargin{:});
command = sprintf('Rscript %s %s', r_file, inputs);

% run
[status, output] = system(command);

