function pdf_file = pdflatex(latex_file,compile_method)
%PDFLATEX   Compile a LaTeX file to make a PDF.
%
%  pdf_file = pdflatex(latex_file, compile_method)
%
%  INPUTS:
%      latex_file:  LaTeX file. A .tex extension is optional.
%
%  compile_method:  method to use when compiling the file:
%                    'pdflatex' - use when you have non-eps
%                    graphics files. 
%                    'latexdvipdf' - use when you have .eps
%                    files, and no other types of graphics.
%                    (Default)
%
%  OUTPUTS:
%        pdf_file:  path to the compiled PDF file.

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

% input checks
if ~exist(latex_file,'file')
  error('%s not found.', latex_file)
end
if ~exist('compile_method','var')
  compile_method = 'latexdvipdf';
end

% strip away the file extension
if strcmp(latex_file(end-3:end), '.tex')
  latex_file = latex_file(1:end-4);
end

pd = pwd;

parent_dir = fileparts(latex_file);
if ~isempty(parent_dir)
  cd(fileparts(latex_file))
end

fprintf('compiling %s...', latex_file)

switch compile_method
  case 'latexdvipdf'
  compile(latex_file, 'latex -interaction=nonstopmode');
  
  % make a PDF
  command = sprintf('dvipdf %s', latex_file);
  unix(command);
  
  case 'pdflatex'
  compile(latex_file, 'pdflatex -interaction nonstopmode');
  
  otherwise
  error('Unknown compiling method: %s', compile_method)
end

% pass out the filename to the PDF
pdf_file = sprintf('%s.pdf', latex_file);
if ~exist(pdf_file,'file')
  error('Problem creating %s.', pdf_file)
end

cd(pd);

function compile(latex_file, compile_command, max_tries)
  % input checks
  if ~exist('latex_file','var')
    error('You must pass a LaTeX file to compile.')
  elseif ~exist('compile_command','var')
    error('You must pass a command to run.')
  end
  if ~exist('max_tries','var')
    max_tries = 3;
  end
  
  tries = 0;
  run = true;
  while run && tries < max_tries
    % run the command
    command = sprintf('%s %s | grep "Rerun LaTeX"', compile_command, latex_file);
    [~,w] = unix(command);

    if isempty(w) % success!
      run = false;
    else % latex says we need to run again
      fprintf('recompiling...')
      tries = tries + 1;
    end
  end
  fprintf('\n')
%endfunction
