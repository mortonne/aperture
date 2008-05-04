function all_subj_report(exp, patname, figname, title, compile, whichEv)
%all_subj_report(exp, patname, figname, title, compile, whichEv)

if ~exist('compile', 'var')
	compile = 0;
end
if ~exist('whichEv', 'var')
  whichEv = 1;
end

% pat = getobj(exp.subj(1), 'pat', patname);
% tempfig = getobj(pat, 'fig', figname);
% try
%   title = tempfig.title;
% catch
%   title = 'plots';
% end

for s=1:length(exp.subj)
  pat = getobj(exp.subj(s), 'pat', patname);
  fig{s} = getobj(pat, 'fig', figname);
end

for n=1:length(fig)
  fig{n}.title = exp.subj(n).id;
  fig{n}.file = fig{n}.file(whichEv,:);
  newfig(n) = fig{n};
end

chan = pat.dim.chan;
resDir = fullfile(fileparts(fileparts(pat.file)), 'reports');
if ~exist(resDir)
  mkdir(resDir);
end

reportfile = fullfile(resDir, [figname '_report']);
report_by_channel(chan, newfig, reportfile, title, compile);
