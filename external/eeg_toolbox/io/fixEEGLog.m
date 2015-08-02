function fixEEGLog(infile,outfile)
%FIXEEGLOG - Fix pyepl EEG Logfile leaving only UP pulses.
%
%
% FUNCTION:
%   fixEEGLog(infile,outfile)
%
% INPUT ARGS:
%   infile = 'eeg.eeglog';
%   outfile = 'eeg.eeglog.up';
%

% read in the logfile
[mstime, maxoffset, type] = textread(infile,'%s%n%s%*[^\n]','emptyvalue',NaN);

% write out new file
fid = fopen(outfile,'w');
for i = 1:length(type)
  if strcmp(type{i},'UP')
    % save it to file
    fprintf(fid,'%s\t%d\t%s\n',mstime{i},maxoffset(i),type{i});
  end
end
fclose(fid);
