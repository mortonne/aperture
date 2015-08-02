function [samplerate,nBytes,dataformat,gain] = GetRateAndFormat(event)
%GETRATEANDFORMAT - Get the samplerate, gain, and format of eeg data.
%
% function [samplerate,nBytes,dataformat,gain] = GetRateAndFormat(event)
%

if ischar(event)
  paramdir = event;
else
  paramdir = fileparts(event.eegfile);
end
paramfile = fullfile(paramdir, 'params.txt');

if ~exist(paramfile, 'file')
  error('EEG parameter file does not exist: %s', paramfile)
end

% get information from the params file
samplerate = eegparams(paramfile, 'samplerate');
gain = eegparams(paramfile, 'gain');
dataformat = eegparams(paramfile, 'dataformat');
if isempty(dataformat)
  %dataformat = 'short';
  error('dataformat not found')
end

if isempty(samplerate)
  error('samplerate not found')
end
if isempty(gain)
  error('gain not found')
end

switch dataformat
 case 'single'
  nBytes=4;
 case {'short','int16'}
  nBytes=2;
 case 'double'
  nBytes=8;
 otherwise
  error('invalid data format');
end

function p = eegparams(paramfile, field)
%EEGPARAMS - Get a subject specific eeg parameter from the params.txt file.
% 
% If paramdir is not specified, the function looks in the 'docs/'
% directory for the params.txt file.
%
% The params.txt file can contain many types of parameters and will
% evaluate them as one per line.  These are examples:
%
% Channels 1:64
% samplerate 256
% subj 'BR015'
%
% FUNCTION:
%   p = eegparams(field,paramdir)
%
% INPUT ARGS:
%   field = 'samplerate';        % Field to retrieve
%   paramdir = '~/eeg/012/dat';  % Dir where to find params.txt
%
% OUTPUT ARGS:
%   p- the parameter, evaluated with eval()
%

% VERSION HISTORY:
%

% input checks
if ~exist('field','var') || ~ischar(field)
  error('You must specify a field to read.')
end

% set the default for standard fields
p = [];

% open the file
in = fopen(paramfile,'rt');
if in==-1
  return
end

% look for the parameter. If not found, return the
% default value
done = false;
while ~done
  f = fscanf(in,'%s',1);
  if strcmp(f, field) % found it
    p = eval(fgetl(in));
    done = true;
  elseif isempty(f) % nothing more to read
    done = true;
  else
    fgetl(in);
  end
end
fclose(in);
