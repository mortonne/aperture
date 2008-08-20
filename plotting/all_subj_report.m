function all_subj_report(exp, patname, figname, title, compile, whichEv)
%ALL_SUBJ_REPORT   Create a PDF report with a channels X subjects table.
%   ALL_SUBJ_REPORT(EXP,PATNAME,FIGNAME,TITLE,COMPILE,WHICHEV) gets the
%   fig object specified by PATNAME and FIGNAME for each subject in EXP,
%   and creates a LaTeX report with figures.  The figures will be
%   arranged in a channels X subjects table.
%
%   TITLE is a string indicating the optional title of the report.
%   If compile is true (default is false), the .tex file will automatically
%   be compiled to create a PDF report.
%
%   If each fig object contains figure filenames for multiple events,
%   WHICHEV must be specified to indicate which event to include in the
%   report.
%
%   See also report_by_channel, longtable.
%

if ~exist('patname','var')
  patname = [];
end
if ~exist('figname','var')
  figname = [];
end
if ~exist('title','var')
  title = '';
end
if ~exist('compile','var')
	compile = 0;
end
if ~exist('whichEv','var')
  whichEv = [];
end

% report saved in pattern_dir/../reports
resDir = fileparts(fileparts(pat.file));
if ~exist(resDir)
  mkdir(resDir);
end
reportfile = fullfile(resDir, 'reports', [figname '_report']);

% get one fig object for each subject
for s=1:length(exp.subj)
  % header of each column is the subject's id
  header{s} = exp.subj(s).id;
  
  % get the specified fig and add it to the vector
  pat = getobj(exp.subj(s), 'pat', patname);
  fig(s) = getobj(pat, 'fig', figname);
  
  if isempty(whichEv)
    if size(fig(s).file,1)>1
      error('You must choose which event of fig %s to include.', figname);
      else
      whichEv = 1;
    end
  end

  % if there are multiple events, choose one
  fig(s).file = fig(s).file(whichEv,:);
end

% chan dims should be the same across subjects; grab one
chan = pat.dim.chan;

% create the LaTeX report
report_by_channel(chan, fig, reportfile, header, title, compile);
