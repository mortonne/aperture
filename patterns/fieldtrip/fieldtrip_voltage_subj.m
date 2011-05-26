function stat_file = fieldtrip_voltage_subj(exp, varargin)

%FIELDTRIP_VOLTAGE_SUBJ  Run fieldtrip on individual subjects for voltage erp.
%
%  stat_file = fieldtrip_voltage_subj(exp, ...)
%
%  INPUTS:
%      exp:  experiment object.
%
%  OUTPUTS:
%      stat_file:  file location for fieldstat obj
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   time_bins = inputs to bin_pattern, ([]);
%   eventFilter1 = string input to filter_pattern for 1st condition;
%   eventFilter2 = string input to filter_pattern for 2nd condition;
%   pat_name = string name of pattern;
%   stat_name = name for fieldtrip stat object;
%   exp_path = string location of your exp structure;
%   skip_objcreate = logical, should we skip stat object creation?; (false)
%   res_dir_stat = directory in which to save the stat object;
%   shuffles = how many randomizations should fieldtrip run?; (1000)
%   numrandomization = defaults.shuffles;
%   adaptive = logical, should we adaptively rerun fieldtrip if p
%              value is close to 0.05?; (false)
%   adaptive_range = for what p values should we rerun fieldtrip?; ([.02 .08])
%   adaptive_shuffles = how many randomizations should we run adaptively?; (5000)
%   layout = where is the layout file located?; ('/home1/zcohen/matlab/HCGSN128_nof.sfp')
%   neighbourdist = what distance defines a neighboring electrode? (.11)
%   neighbours = if you've already calculated a neighbour; []
%   keeptrials = always 'yes';
%   vartrllength = we use NaNs which create different lengths; (2)
%   correctm = how do you want to handle the MCP; always choose ('cluster')
%   clusteralpha = alpha threshold for your cluster analysis; (.025)
%   alphathresh = .025;
%   method = because we are using cluster method we must use; ('montecarlo')
%   clusterstatistic = statistic to use with the cluster analysis; ('maxsum')
%   dimord = dimension order of your data; ('chan_time')
%   minnbchan = minimum number of neighboring electrodes necessary
%               to include an electrode in a cluster; (2)
%   tail = hypothesis about cluster directionality? NO; (0)
%   clustertail = hypothesis about cluster directionality? NO; (0)
%   alpha = .005;
%   statistic = cluster statistic; ('indepsamplesT')
%   keepindividual = keep individual trials for grandaverage; ('yes')
%   computecritval = 'no';
%   clustercritval = this value is for the t-statistic - fieldtrip
%                    compares all effect sizes and masks out those
%                    that don't surpass this in the positive or
%                    negative directions. This is important - it is
%                    used in clusterstat.m to make a mask of where
%                    significant observations were noticed; (.5)
%   clusterthreshold = 'parametric';
%
%
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


% default params
defaults.freq_filter = '';
defaults.time_bins = [];
defaults.eventFilter1 = '';
defaults.eventFilter2 = '';
defaults.pat_name = '';
defaults.stat_name = '';
defaults.exp_path = '';
defaults.skip_objcreate = false;
defaults.res_dir_stat = '';
defaults.res_dir_pat = '';
defaults.fig_dir = '';
defaults.report_name = '';
defaults.shuffles = 1000;
defaults.numrandomization = defaults.shuffles;
defaults.adaptive = false;
defaults.adaptive_range = [.02 .08];
defaults.adaptive_shuffles = 5000;
defaults.layout = '~/matlab/HCGSN128_nof.sfp';
defaults.neighbourdist = .11;
defaults.neighbours = [];
defaults.latency = 'all';
defaults.keeptrials = 'yes';
defaults.vartrllength = 2;
defaults.correctm = 'cluster';
defaults.clusteralpha = .025;
defaults.alphathresh = .025;
defaults.method = 'montecarlo';
defaults.clusterstatistic = 'maxsum';
defaults.dimord = 'chan_time';
defaults.minnbchan = 2;
defaults.tail = 0;
defaults.clustertail = 0;
defaults.alpha = .005;
defaults.statistic = 'indepsamplesT';
defaults.keepindividual = 'yes';
defaults.computecritval = 'no';
defaults.clustercritval = .5;
defaults.clusterthreshold = 'parametric';

[params, extras] = propval(varargin, defaults);

% input checks
%if something
%  error('something something.')
%end


%convert patterns to fieldtrip ready averages
exp.subj = apply_to_subj(exp.subj, @fieldtrip_voltage_subj_statistics, ...
                         {params}, 1, 'memory', '3G');

if params.adaptive
  %run cluster_counter.m to identify significant clusters and reruns
  sigclust = cluster_counter(exp, params.pat_name, params.stat_name, params.adaptive_range);
  %only rerun those who have clusters in the adaptive range
  subj_include = ismember({exp.subj.id}, sigclust.rerun);
  if sum(subj_include) == 0
    return
  else
    params.numrandomization = params.adaptive_shuffles;
    params.overwrite = true;
    params.skip_objcreate = true;
    params.sigclust_rerun = 'yes';
    exp.subj(subj_include) = apply_to_subj(exp.subj(subj_include), @fieldtrip_voltage_subj_statistics, ...
                         {params}, 1, 'memory', '3G');
  end
end


function subj = fieldtrip_voltage_subj_statistics(subj, params)

%warnings are turned off because glm spits out tons of warnings
%that we've decided aren't important
warning('off', 'all');

%fieldtrip needs each condition on a separate pat obj
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
params.neighbours = run_fieldtrip(@ft_neighbourselection, p, data1);

%make space by clearing
clear pat1
clear pat2

%prepares data by averaging and collecting trial info
t = [];
t.keeptrials = params.keeptrials;
t.vartrllength = params.vartrllength;
timelock1 = run_fieldtrip(@ft_timelockanalysis, t, data1);
timelock2 = run_fieldtrip(@ft_timelockanalysis, t, data2);

%make space by clearing
clear data1
clear data2

%data must be in single format
timelock1.trial = cast(timelock1.trial, 'single');
timelock2.trial = cast(timelock2.trial, 'single');

%init a new stat obj
stat_file = fullfile(params.res_dir_stat, objfilename('stat', params.stat_name, ...
                                            subj.id));
stat = init_stat(params.stat_name, stat_file, subj.id, params);

%if you want to save the stat object to hd and add a stat object to
%the exp structure
if ~params.skip_objcreate
subj = setobj(subj, 'pat', params.pat_name, 'stat', stat);
end  

%creates the design definition marking condition type
s1 = size(timelock1.trial, 1);
s2 = size(timelock2.trial, 1);
design = zeros(1, s1+s2);
design(1, 1:s1) = 1;
design(1, (s1+1):(s1+s2)) = 2;
cfg.design = design;

% should we overwrite this pattern?  Regardless of hd or ws
if ~params.overwrite && exist(stat.file, 'file')
  fprintf('stat object "%s" exists. Skipping...\n', params.stat_name)
  return
end

%get the necessary parameters for fieldtrip
p = [];
p.design = [design; ivar_design];
p.keepindividual = params.keepindividual;
p.latency = params.latency;
p.keeptrials = params.keeptrials;
p.neighbours = params.neighbours;
p.vartrllength = params.vartrllength;
p.numrandomization = params.numrandomization;
p.layout = params.layout;
p.neighbourdist = params.neighbourdist;
p.neighbours = params.neighbours;
p.correctm = params.correctm;
p.clusteralpha = params.clusteralpha;
p.alphathresh = params.alphathresh;
p.method = params.method;
p.clusterstatistic = params.clusterstatistic;
p.dimord = params.dimord;
p.minnbchan = params.minnbchan;
p.tail = params.tail;
p.clustertail = params.clustertail;
p.alpha = params.alpha;
p.statistic = params.statistic;
p.computecritval = params.computecritval;
p.clustercritval = params.clustercritval;
p.clusterthreshold = params.clusterthreshold;

%Run the actual fieldtrip cluster analysis
[fieldstat] = run_fieldtrip(@ft_timelockstatistics, p, timelock1, timelock2);

%save the fieldtrip statistic
save(stat.file, 'fieldstat');