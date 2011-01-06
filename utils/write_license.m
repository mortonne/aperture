function write_license(file, license_file)
%WRITE_LICENSE   Add a license header to a file.
%
%  write_license(file, license_file)

MAX_CHAR = 1000000;

% read the M-file
fid = fopen(file);
c = textscan(fid, '%s', 'Delimiter', '', 'EndOfLine', '', 'BufSize', MAX_CHAR);
fclose(fid);

content = c{1}{1};

% read the license header
fid = fopen(license_file);
c = textscan(fid, '%s', 'Delimiter', '', 'EndOfLine', '', 'BufSize', MAX_CHAR);
fclose(fid);
license = c{1}{1};

% get the block before the first blank line
s = regexp(content, '\n\n', 'split');
docstring = s{1};
finish = regexp(content, '\n\n', 'end');
body = content(finish + 1:end);

% stitch the new text together
new = sprintf('%s\n\n%s\n\n%s', docstring, license, body);

% replace the old file
fid = fopen(file, 'w');
fprintf(fid, '%s', new);
fclose(fid);

