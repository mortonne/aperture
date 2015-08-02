function write_chans_file(filename, channels)
%WRITE_CHANS_FILE   Write channel numbers to a text file.
%
%  write_chans_file(filename, channels)
%
%  INPUTS:
%  filename:  path to the file to write channel numbers to.
%
%  channels:  array of channel numbers.

fid = fopen(filename,'w');
fprintf(fid, '%d\n', channels);
fclose(fid);
