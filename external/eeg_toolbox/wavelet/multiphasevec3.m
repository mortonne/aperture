function [phase,pow] = multiphasevec3(f,S,Fs,width,precision)
% FUNCTION [phase,pow] = multiphasevec3(f,S,Fs,width,precision)
%
% Returns the phase and power as a function of time for a range of
% frequencies (f).
%
% INPUT ARGS:
%   f = [2 4 8];   % Frequencies of interest
%   S = dat;       % Signal to process
%   Fs = 256;      % Sampling frequency
%   width = 6;     % Width of Morlet wavelet (>= 5 suggested).
%
% OUTPUT ARGS:
%   phase- Phase data [chans/epochs,freqs,time]
%   power- Power data [chans/epochs,freqs,time]
%   Sfft - descrete Fourier transform of S
%

if nargin < 5
  precision = 'double';
end

nF = length(f);
nS = size(S);

dt = 1/Fs;
st = 1./(2*pi*(f/width));

% get the Morlet's wavelet for each frequency
curWaves = arrayfun( @(i) morlet( f(i), -3.5*st(i):dt:3.5*st(i), width ), 1:nF, 'UniformOutput', false );
nCurWaves = cellfun( @(w) length(w), curWaves );

Lys = nS(2) + nCurWaves - 1;    % length of convolution of S and curWaves{i}
Ly2s = pow2(nextpow2(Lys));     % next power of two (for fft)
ind1 = ceil(nCurWaves/2);       % start index of signal after convolution

pow = zeros(nS(1), nF, nS(2), precision);
phase = zeros(nS(1), nF, nS(2), precision);

for i = 1:nF
    Ly2 = Ly2s(i);
    
    %%% Perform the convolution of curWaves{i} with every row of S
    % take the fft of S and curWaves{i}, multiply them, and take the ifft
    
    % Sfft = fft(S,Ly2,2);
    % curWaveFFT = fft(curWaves{i},Ly2);
    % Y = bsxfun(@times, Sfft, curWaveFFT);
    % y1 = ifft(Y,Ly2,2);
    
    % (EH - it's much quicker to do it in one line)
    y1 = ifft( bsxfun( @times, fft(S,Ly2,2), fft(curWaves{i},Ly2) ) ,Ly2,2);

    y1 = y1( :, ind1(i):(ind1(i)+nS(2)-1) );
    
    % find phase and power (do it inside this loop to save memory)
    pow(:,i,:) = abs(y1).^2;
    phase(:,i,:) = angle(y1);
end
