function write_license(file, license_file)
%WRITE_LICENSE   Add a license header to a file.
%
%  write_license(file, license_file)

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

