function [varargout] = getphasepow(chan,events,DurationMS,OffsetMS,BufferMS,varargin)
%GETPHASEPOW - Calculate wavelet phase and power for a set of events.
%
% Calculate wavelet phase and power as a function of time and frequency for a
% single electrode.
%
% FUNCTION: 
%   [phase,pow,kInd] = getphasepow(chan,events,DurationMS,OffsetMS,BufferMS,varargin)
%
% INPUT ARGs:
%   chan = 2;
%   events = events;
%   DurationMS = 2000;
%   OffsetMS = 0;
%   BufferMS = 1000;
%
%   OPTIONAL PARAMS:
%     'freqs'
%     'width'
%     'filtfreq'
%     'filttype'
%     'filtorder'
%     'resampledrate' - resample applied before calculating phase/power
%     'downsample' - decimate applied after calculating power
%     'powonly'
%     'usesingles'
%     'kthresh'- Kurtosis threshold to throw out events.
%
% OUTPUT ARGS:
%   phase- (Events,Freqs,Time)
%   pow- (Events,Freqs,Time)
%   kInd - logical indexes of the events that were not thrown out due to kurtosis
%   (if no phase is demanded then kInd will be the second output argument)

% Changes:
%
% 6/18/08 - NWM - Changed the processing of varargs.
% 1/6/06 - PBS - Added decimation of phase.
% 9/15/05 - PBS - Added downsampling via decimate following power calculation.
% 9/15/05 - PBS - Return the logical index of the events not thrown out
%                 with the kurtosis thresh.
% 7/8/05 - MvV - Return the index of the events thrown out with the
%                kurtosis threshold if desired
% 1/18/05 - PBS - Ignore the buffer when applying kurtosis.
%                 Changed round to fix when determine durations.
%                 No longer gets double buffer when buffer is specified.
% 10/30/04 - PBS - Added a kthresh option for filtering events with
%                  high kurtosis.
% 8/25/04 - PBS - Made it an option to create phase and pow
%                 matrixes as singles.
% 3/18/04 - PBS - Switched to gete_ms and added ability to resample
% 11/20 josh 1. changed filtfreq to [] rather than 0. 2. Got rid of the 'single()' function calls that were
% forcing us to return single rather than doubles.  it was pretty
% annoying. per was there a good reason for this function to return
% singles?

% set the defaults
def.freqs = eeganalparams('freqs');
def.width = eeganalparams('width');
def.filtfreq = [];
def.filttype = [];
def.filtorder = 1;
def.resampledrate = [];
def.dsample = [];
def.powonly = 0;
def.usesingles = 0;
def.keepk = 0;
def.kthresh = [];

% process the inputs
[eid,emsg,freqs,width,filtfreq,filttype,filtorder,resampledRate,dsample,powonly,usesingles,keepk,kthresh] = getargs(fieldnames(def),struct2cell(def),varargin{:});

% get some parameters
[samplerate,nBytes,dataformat,gain] = GetRateAndFormat(events(1));
rate = eegparams('samplerate',fileparts(events(1).eegfile));
samplerate = rate;
if ~isempty(resampledrate)
  resampledrate = round(resampledrate);
  samplerate = resampledrate;
  rate = resampledrate;
end

% convert the durations to samples
duration = fix((DurationMS+(2*BufferMS))*rate/1000);
offset = fix((OffsetMS-BufferMS)*rate/1000);
buffer = fix((BufferMS)*rate/1000);


% load the eeg
eeg = gete_ms(chan,events,DurationMS+(2*BufferMS),OffsetMS-BufferMS,0,filtfreq,filttype,filtorder,samplerate);

% see if throw out events with weird kurtosis
if ~isempty(kthresh)
  startsize = size(eeg,1);
  k = kurtosis(eeg(:,buffer+1:end-buffer)');
  goodInd = k<=kthresh;
  %kInd = setdiff(1:size(eeg,1),goodInd);
  kInd = goodInd;
  if keepk
    kInd = k>kthresh;
  else
    eeg = eeg(goodInd,:);
  end
  sizediff = startsize - size(eeg,1);
  if sizediff > 0
    fprintf('Threw out %d events due to kurtosis...\n',sizediff);
  end
else
  kInd = logical(ones(size(eeg,1),1));
  if keepk
    kInd = logical(zeros(size(eeg,1),1));
  end
end

% zero out the data
if usesingles
  if ~powonly
    phase = single(zeros(size(eeg,1),size(freqs,2),size(eeg,2)));
  end
  pow = single(zeros(size(eeg,1),size(freqs,2),size(eeg,2)));
else
  if ~powonly
    phase = zeros(size(eeg,1),size(freqs,2),size(eeg,2));
  end
  pow = zeros(size(eeg,1),size(freqs,2),size(eeg,2));
end
  
% get the power
if length(events) > 1
  fprintf('Events: %g\n',size(eeg,1)); 
end
for j = 1:size(eeg,1)
  if powonly
    [phase,pow(j,:,:)] = multiphasevec2(freqs,eeg(j,:),samplerate,width);
  else
    [phase(j,:,:),pow(j,:,:)] = multiphasevec2(freqs,eeg(j,:),samplerate,width);
  end
  
  if length(events) > 1
    fprintf('%g ',j);
  end
end

if length(events) > 1
  fprintf('\n');
end

% remove the buffer
pow = pow(:,:,buffer+1:end-buffer);
if ~powonly
  phase = phase(:,:,buffer+1:end-buffer);
end

% see if decimate power
if ~isempty(dsample)
  % set the downsampled duration
  dmate = round(samplerate/dsample);
  dsDur = ceil(size(pow,3)/dmate);

  if usesingles
    precision = 'single';
  else
    precision = 'double';
  end
  dpow = zeros(size(pow,1),size(pow,2),dsDur,precision);
  if ~powonly
    dphase = zeros(size(phase,1),size(phase,2),dsDur,precision);
  end
  
  % Must log transform power before decimating
  pow(pow<=0) = eps;
  pow = log10(pow);
  
  % loop and decimate
  fprintf('\nDecimating: %d\n ',size(pow,1));
  for e = 1:size(pow,1)
    fprintf('%d ',e);
    for f = 1:size(pow,2)
      dpow(e,f,:) = decimate(double(pow(e,f,:)),dmate);
      if ~powonly
        % decimate the unwraped phase, then wrap it back
        dphase(e,f,:) = mod(decimate(double(unwrap(phase(e,f,:))),dmate)+pi,2*pi)-pi;
      end
    end
  end
  fprintf('\n');
  
  % replace old pow with new
  pow = dpow;
  clear dpow;
  if ~powonly
    phase = dphase;
    clear dphase;
  end
  
  % convert back to no-log
  pow = 10.^pow;

end

if ~powonly
  varargout(1) = {phase};
  varargout(2) = {pow};
  varargout(3) = {kInd};
else
  varargout(1) = {pow};
  varargout(2) = {kInd};
end

