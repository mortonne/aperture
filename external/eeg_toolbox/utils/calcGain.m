function gain = calcGain(ampinfo,ampfact)
%CALCGAIN - Calculate the gain factor to convert raw EEG to uV.
%
% FUNCTION:
%   gain = calcGain(ampinfo,ampfact)
%
% INPUT ARGS:
%   ampinfo = [-2048 2048; -5 5];  % Conversion info from raw
%                              %   to voltage (default)
%   ampfact = 10000;           % Amplification factor to
%                              %   correct for (default)
%
% OUTPUT ARGS:
%   gain - factor to convert data.
%
%


% perform amp conversions
arange = abs(diff(ampinfo(1,:)));
drange = abs(diff(ampinfo(2,:)));

% see if centered around zero for faster operation
if diff(abs(ampinfo(1,:))) == 0 & diff(abs(ampinfo(2,:)))==0
  % are both centered at zero, so get converstion factor
  gain = (drange*10^6/ampfact)/arange;
else
  % not centered, so can't calc sinlge factor
  warning(['Amp. Info ranges were not centered at zero.\nNo gain' ...
	   ' calculation was possible']);
  gain = 1;
end
