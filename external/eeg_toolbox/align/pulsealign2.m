function [good_beh_ms,eeg_offset] = pulsealign2(beh_ms,pulses)
%PULSEALIGN - Pick matching behavioral and eeg pulses.
%
% This method picks matching behavioral and eeg pulses from the
% beginning and end of the behavioral period for use with the
% logalign function to align behavioral and eeg data.
%
% This is josh's pimped version of this code that should work a lot better.... 12/9/09
%
% FUNCTION:
%   function [beh_ms,eeg_offset] = pulsealign2(beh_ms,pulses,pulseIsMS)
%
% INPUT ARGS:
%   beh_ms = beh_ms;   % A vector of ms times extracted from the
%                      %  log file
%   pulses = pulses;   % Vector of eeg pulses extracted from the eeg
%
% OUTPUT ARGS:
%   beh_ms- The truncated beh_ms values that match the eeg_offset
%   eeg_offset- The trucated pulses that match the beh_ms
%
% 1/15/07 MvV: added functionality to align neuralynx pulses. These
% pulses are already in ms. .


%JJ on how this algorithm works:
%  Step through the recorded sync pulses in chunks of  windsize.  Use corr to find the chunks of behavioral pulse times where the inter-pulse intervals are correlated.  When the maximum correlation is greater than corrThresh, then it indicates that the pairs match.

%note that sampling rate never comes in here. this is how alignment should work---it should be entirely sampling-rate independent....

%!%%
%these are parameters that one could potentially tweak....
windSize=10;
%windSize=15;
corrThresh=.99;
%%%

eegBlockStart=1:windSize:length(pulses)-windSize;

% $$$ 
% $$$ for b=1:length(eegBlockStart)
% $$$   eeg_pulseTimes=pulses(eegBlockStart(b)+[0:windSize-1]);
% $$$ 
% $$$   for i=1:length(beh_ms)-length(eeg_pulseTimes)+1
% $$$     beh_pulseTimes=beh_ms(i+[0:windSize-1]);    
% $$$ %    [r(i),p(i)]=corr(diff(eeg_pulseTimes),diff(beh_pulseTimes));
% $$$     [r(i),p(i)]=corr(diff(eeg_pulseTimes),diff(beh_pulseTimes),'type','kendall');
% $$$   end
% $$$   [blockR(b),blockBehMatch(b)]=max(r);
% $$$ end


 beh_d=diff(beh_ms);
 beh_d(beh_d>5*1000)=0; %if any interpulse differences  are greater than five seconds, throw them out!
 pulse_d=diff(pulses);
 
 disp(sprintf('%d blocks',length(eegBlockStart)));
 for b=1:length(eegBlockStart)
   fprintf('.');
   eeg_d=pulse_d(eegBlockStart(b)+[0:windSize-1]);
   r=zeros(1,length(beh_d)-length(eeg_d));p=r;
   for i=1:(length(beh_d)-length(eeg_d))  
%     [r(i),p(i)]=corr(eeg_d,beh_d(i+[0:windSize-1]));
%     r(i)=corr(eeg_d,beh_d(i+[0:windSize-1]));     
    r(i)=fastCorr(eeg_d,beh_d(i+[0:windSize-1]));     
   end
   [blockR(b),blockBehMatch(b)]=max(r);
 end
   fprintf('\n');
%now, for each block, check if it had a good correlation.  if so, then add the set of matching pulses into the output

eeg_offset=[];
good_beh_ms=[];

for b=find(blockR>corrThresh)
  x=pulses(eegBlockStart(b)+[0:windSize-1]);
  eeg_offset=[eeg_offset;x];
  y=beh_ms(blockBehMatch(b)+[0:windSize-1]);
  good_beh_ms=[good_beh_ms; y];
end

disp(sprintf('found matches for %d of %d pulses',length(eeg_offset),length(pulses)));

if (length(eeg_offset) / length(pulses)) < 0.1
  warning('eeg_toolbox:pulsealign:poorMatch', ...
          'Fewer than one tenth of pulses matched.');
end

%keyboard

function r=fastCorr(x,y)
%josh's faster version of corr
c=cov(x,y);
r=c(1,2)./(std(x)*std(y));

