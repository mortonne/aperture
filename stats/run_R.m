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

if ~(ismac || isunix)
  warning('Designed for UNIX or Mac; may fail for Windows.')
end

% find the full path to the script
r_file = which(r_script);

% create the command
inputs = sprintf('%s ', varargin{:});
command = sprintf('Rscript %s %s', r_file, inputs);

% run
[status, output] = system(command);

