function [phase,pow]=multiphasevec(f,S,Fs,width,useSingles)
% FUNCTION [phase,pow]=multiphasevec(f,S,Fs,width)
%
% Returns the phase and power as a function of time for a range of
% frequencies (f).
%
% Simply calls phasevec in a loop.
%
% INPUT ARGS:
%   f = [2 4 8];   % Frequencies of interest
%   S = dat;       % Signal to process
%   Fs = 256;      % Sampling frequency
%   width = 6;     % Width of Morlet wavelet (>= 5 suggested).
%   useSingles=false;
%
% OUTPUT ARGS:
%   phase- Phase data [freqs,time]
%   power- Power data [freqs,time]
%




if exist('useSingles','var') && useSingles==true
  pow = zeros(length(f),length(S),'single');
  phase = zeros(length(f),length(S),'single');  

else
  pow = zeros(length(f),length(S));
  phase = zeros(length(f),length(S));  
end

for a=1:length(f)
     [phase(a,:),pow(a,:)]=phasevec(f(a),S,Fs,width);
end
