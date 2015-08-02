function y = buttfilt(dat,freqrange,samplerate,filttype,order)
%BUTTFILT - Wrapper to Butterworth filter.
%
% Butterworth filter wrapper function with zero phase distortion.
%
% FUNCTION:
%   y = buttfilt(dat,freqrange,samplerate,filttype,order)
%
% INPUT ARGS: (defaults shown):
%   dat = dat;                % data to be filtered (required)
%   freqrange = [58 62];  % filter range (depends on type)
%   samplerate = 256;         % sampling frequency
%   filttype = 'stop';        % type of filter 
%                             %   ('bandpass','low','high','stop') 
%   order = 4;                % order of the butterworth filter
%
% OUTPUT ARGS::
%   y = the filtered data
%

% 12/1/04 - PBS - Will now filter multiple times if requested

% check the args
if nargin < 5
  order = 4;
  if nargin < 4
    filttype = 'stop';
    if nargin < 3
      samplerate = 256;
      if nargin < 2
	freqrange = [58 62];
      end
    end
  end
end

% Nyquist frequency
nyq=samplerate/2;   

for i = 1:size(freqrange,1)
  % get the butterworth values
  [Bb, Ab]=butter(order, freqrange(i,:)/nyq, filttype);

  % run the filtfilt for zero phase distortion
  dat = filtfilt(Bb,Ab,dat);
end

y = dat;


