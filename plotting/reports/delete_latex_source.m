function delete_latex_source(source_file)
%DELETE_LATEX_SOURCE   Delete source files for compiling a LaTeX document.
%
%  delete_latex_source(source_file)

if ~exist(source_file, 'file')
  error('Source file does not exist: %s', source_file)
end

[pathstr, name, ext] = fileparts(source_file);
source_base = fullfile(pathstr, name);
pdf_file = [source_base '.pdf'];

if ~exist(pdf_file, 'file')
  return
end

source_mod_time = getfield(dir(source_file), 'datenum');
pdf_mod_time = getfield(dir(pdf_file), 'datenum');
if pdf_mod_time > source_mod_time
  % only clean if the PDF is newer than the source file; this
  % prevents removal of source files if rerunning a function that
  % successfully compiled previously, but now the source file is
  % changed and there was an issue with compiling
  d = dir([source_base '*']);
  for i = 1:length(d)
    [pathstr, name, ext] = fileparts(d(i).name);
    if ~strcmp(ext, '.pdf')
      delete([source_base ext]);
    end
  end
end

