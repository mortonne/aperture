function [beh_ms,eeg_offset] = pulsealign(beh_ms,pulses,samplerate,threshMS,window,doplot,pulseIsMS)
%PULSEALIGN - Pick matching behavioral and eeg pulses.
%
% This method picks matching behavioral and eeg pulses from the
% beginning and end of the behavioral period for use with the
% logalign function to align behavioral and eeg data.
%
% FUNCTION:
%   [beh_ms,eeg_offset] = pulsealign(beh_ms,pulses,samplerate,threshMS,window,pulseIsMS)
%
% INPUT ARGS:
%   beh_ms = beh_ms;   % A vector of ms times extracted from the
%                      %  log file
%   pulses = pulses;   % Vector of eeg pulses extracted from the eeg
%   samplerate = 500;  % Samplerate of the eeg data
%   threshMS = 10;     % The threshold for matching (bigger is
%                      %  weaker criterion)
%   window = 100;      % The number of events to match at the
%                      %  beginning and end
%   pulseIsMS = 1      % set to 1 if pulses are given in ms (as
%   opposed to samples); this would be mostly the case for the
%   neuralynx events, once they have been divided by 1000
%
% OUTPUT ARGS:
%   beh_ms- The truncated beh_ms values that match the eeg_offset
%   eeg_offset- The trucated pulses that match the beh_ms
%
% 1/15/07 MvV: added functionality to align neuralynx pulses. These
% pulses are already in ms. .


if ~exist('samplerate','var')
  samplerate = 500;
end
if ~exist('threshMS','var')
  threshMS = 42/4;
end
if ~exist('window','var')
  window = 100;
end
if ~exist('doplot','var')
  doplot = 0;
end
if ~exist('pulseIsMS','var')
  pulseIsMS = 0;
end

% save a min window
min_window = 5;
start_window = window;

% convert pulses to ms
if ~pulseIsMS
  pulse_ms = pulses*1000/samplerate;
else
  pulse_ms = pulses;
end
  
% remove all pulses under 100ms
dp = diff(pulse_ms);
yp = find(dp < 100);
pulse_ms(yp+1) = [];
pulses(yp+1) = [];


% Search for start and end windows
while window >= min_window
  % try and match from beginning
  start_beh_ind = [];
  for i=1:length(pulse_ms)-window;
    start_beh_ind = seq_find(diff(pulse_ms(i:i+window)),diff(beh_ms),threshMS);
    if ~isempty(start_beh_ind)
      break;
    end
  end
  
  start_pulse_ind = i;
  
  if isempty(start_beh_ind)
    %error('No matching start window');
    % no start found, so decrease window
    window = window - 10;
    continue
  elseif length(start_beh_ind) > 1
    error('Too many matches! You have to lower you threshold.');
  else
    % it's all good
    % save the start window size
    start_window = window;
    
    % tell them if we shrunk the window
    if window ~= start_window
      warning('Reduced start window to %d.',window)
      
      % reset the window
      window = start_window;
    end
    break;
  end
  
end

% see if they found start and end
if isempty(start_beh_ind)
  if doplot
    plot(beh_ms)
    hold on
    plot(pulse_ms,'r')
    hold off
  end
  error('eeg_toolbox:pulsealign:NoMatchStart', 'No matching start window');
end

% Search for the end window
while window >= min_window
  % try and match from end
  end_beh_ind = [];
  for i=(length(pulse_ms)-window):-1:1
    end_beh_ind = seq_find(diff(pulse_ms(i:i+window)),diff(beh_ms),threshMS);
    if ~isempty(end_beh_ind)
      break;
    end
  end
  
  end_pulse_ind = i;

  if isempty(end_beh_ind)
    %error('No matching start window');
    % no start found, so decrease window
    window  = window - 10;
    continue
  elseif length(end_beh_ind) > 1
    error('Too many matches! You have to lower you threshold.');
  else
    % it's all good
    % save the end_window
    end_window = window;
  
    % tell them if we shrunk the window
    if window ~= start_window
      warning('Reduced end window to %d.',window)
      
      % reset the window
      window = start_window;
    end
    break;
  end
end

% see if they found start and end
if isempty(end_beh_ind)
  if doplot
    plot(beh_ms)
    hold on
    plot(pulse_ms,'r')
    hold off
  end
  error('No matching end window');
end

if start_beh_ind+window > end_beh_ind
  % we overlap
  warning('eeg_toolbox:pulsealign:WindowOverlap', ...
          'The start and end windows overlap.');
end

% return the matching values
beh_range = union(start_beh_ind:start_beh_ind+start_window-1, end_beh_ind:end_beh_ind+end_window-1);
beh_ms = beh_ms(beh_range);

pulse_range = union(start_pulse_ind:start_pulse_ind+start_window-1, end_pulse_ind:end_pulse_ind+end_window-1);
eeg_offset = pulses(pulse_range);

fprintf('Start window = %d; End window = %d;\n',start_window,end_window);

function ind = seq_find(needle, haystack, delta)
%SEQ_FIND - Finds a needle in a haystack

% get starting points
ind = find(abs(haystack-needle(1)) < delta);
for c=2:length(needle)
    ind = intersect(ind, find(abs(haystack-needle(c)) < delta)-c+1);
    if isempty(ind)
      break
    end
end

return

