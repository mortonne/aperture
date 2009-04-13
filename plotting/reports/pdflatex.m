function pdf_file = pdflatex(latex_file)
%PDFLATEX   Compile a LaTeX file to make a PDF.
%
%  pdf_file = pdflatex(latex_file)

% input checks
if ~exist(latex_file,'file')
  error('%s not found.', latex_file)
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

% compile the LaTeX code
max_tries = 10;
tries = 0;
run = true;
while run && tries < max_tries
  % run latex
  command = sprintf('latex %s | grep "Rerun LaTeX"', latex_file);
  [s,w] = unix(command);
  
  if isempty(w) % success!
    run = false;
    else % latex says we need to run again
    fprintf('recompiling...')
    tries = tries + 1;
  end
end
fprintf('\n')

% make a PDF
command = sprintf('dvipdf %s', latex_file);
unix(command);

% pass out the filename to the PDF
pdf_file = sprintf('%s.pdf', latex_file);
if ~exist(pdf_file,'file')
  error('Problem creating %s.', pdf_file)
end

cd(pd);
