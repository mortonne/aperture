function stat_file = fieldtrip_voltage(exp, varargin)

%FIELDTRIP_VOLTAGE  Run fieldtrip for voltage erp.
%
%  output = fieldtrip_voltage(exp, ...)
%
%  INPUTS:
%      exp:  experiment object.
%
%  OUTPUTS:
%      fieldstat_file:  file location for fieldstat obj
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
%   statistic = cluster statistic; ('depsamplesT')
%   uvar = which row in design contains unit variable; (1)
%   ivar = which row in design contains independent variable; (2)
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
defaults.layout = '/home1/zcohen/matlab/HCGSN128_nof.sfp';
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
defaults.statistic = 'depsamplesT';
defaults.uvar = 1;
defaults.ivar = 2;
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
exp.subj = apply_to_subj(exp.subj, @fieldtrip_voltage_prepare, ...
                         {params}, 1, 'memory', '3G');


%aggregate averages and designs
averages1 = {};
averages2 = {};
design = [];
for i = 1:length(exp.subj)
  averages1 = {averages1{:} exp.subj(i).timelock1};
  averages2 = {averages2{:} exp.subj(i).timelock2};
  design = [design, i];

  %clear space in memory
  exp.subj(i).timelock1 = [];
  exp.subj(i).timelock2 = [];
end

params.neighbours = exp.subj(1).neighbours;

%finish creating design matrix
design = [design, design];
ivar_design = zeros(1,length(design));
ivar_design(1:length(exp.subj)) = 1;
ivar_design(length(exp.subj)+1:end) = 2;

%make space
clear exp

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
p.uvar = params.uvar;
p.ivar = params.ivar;
p.computecritval = params.computecritval;
p.clustercritval = params.clustercritval;
p.clusterthreshold = params.clusterthreshold;

%make time locked grand average patterns
[grandavg1] = ft_timelockgrandaverage(p, averages1{:});
[grandavg2] = ft_timelockgrandaverage(p, averages2{:});

%clear space
clear design
clear averages1
clear averages2

%run fieldtrip statistical analysis
[fieldstat] = ft_timelockstatistics(p, grandavg1, grandavg2);

%need to create director first
%then make file name
stat_file = strcat(params.res_dir_stat, '/fieldstat_', params.report_name);

%save file
save(stat_file, 'fieldstat')
