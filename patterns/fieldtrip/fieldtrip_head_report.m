function pdf_file = fieldtrip_head_report(exp, pat_name, varargin)

%FIELDTRIP_HEAD_REPORT  Create headplot report with fieldtrip clusters.
%
%  pdf_file = fieldtrip_head_report(exp, ...)
%
%  INPUTS:
%      exp:  experiment object
%      pat_name:  pattern name
%
%  OUTPUTS:
%      pdf_file:  pdf file location
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   stat_file: if you want to use a fieldstat object you've already
%              created, then load from this file and use these
%              parameters
%   time_bins: inputs to bin_pattern, ([]);
%   eventFilter1: string input to filter_pattern for 1st condition;
%   eventFilter2: string input to filter_pattern for 2nd condition;
%   stat_name: name for fieldtrip stat object;


% options
defaults.stat_file = '';
defaults.time_bins = [];
defaults.eventFilter1 = '';
defaults.eventFilter2 = '';
defaults.eventbinlabels = {'type1' 'type2'};
defaults.stat_name = '';
defaults.res_dir_stat = '';
defaults.report_name = 'fieldtrip_headplot_report';
defaults.contrast_str = 'contrast';
defaults.shuffles = 1000;
defaults.numrandomization = 1000;
defaults.statistic = 'depsamplesT';
defaults.uvar = 2;
defaults.ivar = 1;
defaults.cluster_thresh = .05;
defaults.print_input = {'-djpeg50'};
defaults.res_dir = '';
defaults.dist = 0;
defaults.compile_method = 'pdflatex';
defaults.pat_name = pat_name;
defaults.report_title = 'difference headplots with fieldtrip clusters';

params = propval(varargin, defaults);

%input checks
if isempty(params.stat_file)
  %run fieldtrip analysis
  p = [];
  p.time_bins = params.time_bins;
  p.eventFilter1 = params.eventFilter1;
  p.eventFilter2 = params.eventFilter2;
  p.pat_name = pat_name;
  p.stat_name = params.stat_name;
  p.report_name = params.report_name;
  p.shuffles = params.shuffles;
  p.numrandomization = params.shuffles;
  p.statistic = params.statistic;
  p.uvar = params.uvar;
  p.ivar = params.ivar;
  p.dist = params.dist;

  if isempty(params.res_dir_stat)
    params.res_dir_stat = [exp.resDir '/eeg/' params.pat_name '/stats'];
  end
  p.res_dir_stat = params.res_dir_stat;

  if ~exist(p.res_dir_stat, 'dir')
    mkdir(p.res_dir_stat)
  end

  fieldstat_file = fieldtrip_voltage(exp, p);
else
  %use the stat_file already created and get the params from here
  fieldstat_file = params.stat_file;
end

load(fieldstat_file);
params.time_bins = fieldstat.params.time_bins;
params.eventFilter1 = fieldstat.params.eventFilter1;
params.eventFilter2 = fieldstat.params.eventFilter2;
params.stat_name = fieldstat.params.stat_name;
  
%filter, bin, and concatenate all subjs' patterns
pat = cat_all_subj_patterns(exp.subj, pat_name, 1, ...
                             {'event_bins',{params.eventFilter1 params.eventFilter2}, ...
                              'dist', params.dist, ...
                              'event_bin_labels', params.eventbinlabels, ...
                              'save_as', [pat_name '_' params.contrast_str]});

%make grand average pattern
pat_ga = bin_pattern(pat, {'eventbins', 'label', 'save_mats', ...
                    true, 'save_as', [pat.name '_ga'], ...
                    'overwrite', true});

%time bin ga pattern to reflect fieldtrip time bins
pat_ga_tbin = bin_pattern(pat_ga, 'timebins', params.time_bins, 'overwrite', true, 'save_as', [pat_ga.name sprintf('_%sbins',num2str(length(params.time_bins)))]);

%initiate and add a stat object for the fieldstat
stat = init_stat(params.stat_name, fieldstat_file, pat_ga_tbin.source, params);
pat_ga_tbin = setobj(pat_ga_tbin,'stat',stat);

%put the new pat object on the exp structure
exp = setobj(exp, 'pat', pat_ga_tbin);

%load the fieldtrip stat object
load(stat.file);
pos = fieldstat.posclusters(1);
neg = fieldstat.negclusters(1);

%find the positive and negative clusters and make significance
%masks if below cluster threshold
if pos.prob < params.cluster_thresh
  pos_hmask = fieldstat.posclusterslabelmat==1;
  pos_hmask = permute(pos_hmask, [3 1 2]);
else
  pos_hmask = [];
end

if neg.prob < params.cluster_thresh
  neg_hmask = fieldstat.negclusterslabelmat==1;  
  neg_hmask = permute(neg_hmask, [3 1 2]);
else
  neg_hmask = [];
end

%make new event_bins
event_bins = {sprintf('strcmp(label,''%s'')',params.eventbinlabels{1}) ...
              sprintf('strcmp(label,''%s'')',params.eventbinlabels{2})};

%make headplots
pat_ga_tbin =  pat_topoplot_fieldtrip(pat_ga_tbin, [params.contrast_str '_head_ft'], {'event_bins', event_bins, ...
                      'event_labels', params.eventbinlabels, 'plot_type', 'head', ...
		      'diff', true, 'head_markchans', true, 'mark_pos', pos_hmask, 'mark_neg', neg_hmask});

if ~isempty(params.report_name)
  report_dir = get_pat_dir(pat_ga_tbin, 'reports');
  report_file = fullfile(report_dir, params.report_name);
else
  report_file = '';
end

pdf_file = pat_report(pat_ga_tbin, 3, ...
           {[params.contrast_str '_head_ft']}, ...
           'landscape', false, ...
           'title', params.report_title, ...
           'report_file', report_file, ...
           'compile_method', params.compile_method);

