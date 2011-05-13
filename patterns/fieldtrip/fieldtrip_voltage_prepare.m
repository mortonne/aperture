function subj = fieldtrip_voltage_prepare(subj, varargin)

%FIELDTRIP_VOLTAGE_PREPARE  Prepare fieldtrip for voltage erp.
%
%  subj = fieldtrip_voltage_prepare(subj, ...)
%
%  INPUTS:
%      subj:  subj object.
%
%  OUTPUTS:
%      subj:  subj object with design, timelock1 and timelock2
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%
%   time_bins = [];
%   eventFilter1 = '';
%   eventFilter2 = '';
%   pat_name = '';
%   layout = '/home1/zcohen/matlab/HCGSN128_nof.sfp';
%   neighbourdist = .11;
%   neighbours = []; gets set below by neighbourselection.m
%   keeptrials = 'yes';
%   vartrllength = 2;

% Copyright 2007-2011 Neal Morton, Sean Polyn, Zachary Cohen, Matthew Mollison.
%
% This file is part of EEG Analysis Toolbox.
%
% EEG Analysis Toolbox is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% EEG Analysis Toolbox is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser General Public License
% along with EEG Analysis Toolbox.  If not, see <http://www.gnu.org/licenses/>.

% input checks
%if something
%  error('something something.')
%end

% default params
defaults.freq_filter = '';
defaults.time_bins = [];
defaults.eventFilter1 = '';
defaults.eventFilter2 = '';
defaults.pat_name = '';
defaults.layout = '/home1/zcohen/matlab/HCGSN128_nof.sfp';
defaults.neighbourdist = .11;
defaults.neighbours = [];
defaults.keeptrials = 'yes';
defaults.vartrllength = 2;

[params, saveopts] = propval(varargin, defaults);

% input checks
%if ~exist('pat', 'var') || ~isstruct(pat)
%  error('You must input a pattern object.')
%end

%get pat object and replicate
pat1 = getobj(subj, 'pat', params.pat_name);
pat2 = pat1;

%event filter pats
pat1 = filter_pattern(pat1, 'save_mats', false, 'event_filter', params.eventFilter1);
pat2 = filter_pattern(pat2, 'save_mats', false, 'event_filter', params.eventFilter2);

%freq filter pats
if ~isempty(params.freq_filter)
  pat1 = filter_pattern(pat1, 'save_mats', false, 'freq_filter', params.freq_filter);
  pat2 = filter_pattern(pat2, 'save_mats', false, 'freq_filter', params.freq_filter);
end
  
%time bin pats
pat1 = bin_pattern(pat1, 'save_mats', false, 'timebins', params.time_bins);
pat2 = bin_pattern(pat2, 'save_mats', false, 'timebins', params.time_bins);

%run post_timebin to make sure all bins are of same size
pat1 = post_timebin(pat1);
pat2 = post_timebin(pat2);

%convert pat object to fieldtrip format
data1 = pat2fieldtrip(pat1);
data2 = pat2fieldtrip(pat2);

%calculate neighbors based on 3D electrode layout and distance
%parameter, which I set based on how many neighbors it selected and
%by examining each electrode to make sure peripheral electrodes had
%enough neighbors but minimize the amount of neighbors the electrodes
%on the top of the head had
p = [];
p.layout = params.layout;
p.neighbourdist = params.neighbourdist;
params.neighbours = run_fieldtrip(@neighbourselection, p, data1);

%make space by clearing
clear pat1
clear pat2

%prepares data by averaging and collecting trial info
t = [];
t.keeptrials = params.keeptrials;
t.vartrllength = params.vartrllength; 
timelock1 = run_fieldtrip(@timelockanalysis, t, data1);
timelock2 = run_fieldtrip(@timelockanalysis, t, data2);

%make space by clearing
clear data1
clear data2

%data must be in single format
timelock1.trial = cast(timelock1.trial, 'single');
timelock2.trial = cast(timelock2.trial, 'single');

%create design parameter
s1 = size(timelock1.trial, 1);
s2 = size(timelock2.trial, 1);
design = zeros(1, s1+s2);
design(1, 1:s1) = 1;
design(1, (s1+1):(s1+s2)) = 2;

subj.design = design;
clear design

subj.timelock1 = timelock1;
clear timelock1

subj.timelock2 = timelock2;
clear timelock2

subj.neighbours = params.neighbours;