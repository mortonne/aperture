function pdf_file = fieldtrip_head_report_subj(exp, pat_name, varargin)

%FIELDTRIP_HEAD_REPORT_SUBJ  Create headplot report with fieldtrip
%                            clusters for every subject.
%
%  pdf_file = fieldtrip_head_report_subj(exp, ...)
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
defaults.freq_filter = '';
defaults.stat_file = '';
defaults.time_bins = [];
defaults.eventFilter1 = '';
defaults.eventFilter2 = '';
defaults.eventbinlabels = {'type1' 'type2'};
defaults.stat_name = '';
defaults.res_dir_stat = '';
defaults.overwrite = false;
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


%run fieldtrip stat creation if necessary
if isempty(params.res_dir_stat)
  %run fieldtrip analysis
  p = [];
  p.time_bins = params.time_bins;
  p.freq_filter = params.freq_filter;
  p.eventFilter1 = params.eventFilter1;
  p.eventFilter2 = params.eventFilter2;
  p.pat_name = pat_name;
  p.stat_name = params.stat_name;
  p.overwrite = params.overwrite;
  p.report_name = params.report_name;
  p.shuffles = params.shuffles;
  p.numrandomization = params.shuffles;
  p.statistic = params.statistic;
  p.uvar = params.uvar;
  p.ivar = params.ivar;
  p.dist = params.dist;

  if isempty(params.res_dir_stat)
    p.res_dir_stat = [exp.resDir '/eeg/' params.pat_name '/stats'];
  else
    p.res_dir_stat = params.res_dir_stat;
  end
  if ~exist(p.res_dir_stat, 'dir')
    mkdir(p.res_dir_stat)
  end

  exp = fieldtrip_voltage_subj(exp, params);
end


exp.subj = apply_to_subj(exp.subj, @fieldtrip_subj_headplot, {params}, ...
                         0, 'memory', '3G');


report_pat_name = [params.pat_name '_' params.contrast_str];

pat = getobj(exp.subj(1),'pat',report_pat_name);
report_dir = get_pat_dir(pat, 'reports');
report_file = fullfile(report_dir, params.report_name);

pdf_file = pat_report_all_subj(exp.subj, report_pat_name, ...
           {[params.contrast_str '_head_ft']}, ...
           'landscape', true, ...
           'title', params.report_title, ...
           'report_file', report_file, ...
           'compile_method', params.compile_method);


function subj = fieldtrip_subj_headplot(subj, params)

 stat = getobj(subj,'pat',params.pat_name,'stat',params.stat_name);
 load(stat.file);

 params.time_bins = fieldstat.params.time_bins;
 params.freq_filter = fieldstat.params.freq_filter;
 params.eventFilter1 = fieldstat.params.eventFilter1;
 params.eventFilter2 = fieldstat.params.eventFilter2;
 params.stat_name = fieldstat.params.stat_name;
 
 
 pat = getobj(subj,'pat',params.pat_name);
 pat = bin_pattern(pat,'eventbins',{params.eventFilter1 ...
                     params.eventFilter2},'eventbinlabels', ...
                   params.eventbinlabels,'timebins', ...
                   params.time_bins, 'save_as', ...
                   [params.pat_name '_' params.contrast_str], ...
                   'overwrite', true);
 
 if ~isempty(params.freq_filter)
   pat = filter_pattern(pat, {'freq_filter', params.freq_filter});
 end
 
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
 pat =  pat_topoplot_fieldtrip(pat, [params.contrast_str '_head_ft'], {'event_bins', event_bins, ...
                     'event_labels', params.eventbinlabels, 'plot_type', 'head', ...
                     'diff', true, 'head_markchans', true, 'mark_pos', ...
                     pos_hmask, 'mark_neg', neg_hmask, 'print_input', ...
                     params.print_input});
 
 subj = setobj(subj,'pat',pat);
 
