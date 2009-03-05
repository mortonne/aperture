function custom_report(exp, reportname, title, whichPats, whichFigs, figtitles, compile)
%custom_report(exp, reportname, title, whichPats, whichFigs, figtitles, compile)
%
%  *** DEPRECATED ***
%

if ~exist('compile', 'var')
	compile = 0;
end

pat = getobj(exp.subj(1), 'pat', whichPats{1});
resDir = fullfile(fileparts(fileparts(fileparts(pat.file))), 'reports', reportname);
if ~exist(resDir, 'dir')
  mkdir(resDir);
end

for s=1:length(exp.subj)
  n = 1;
  
  for p=1:length(whichPats)
    pat = getobj(exp.subj(s), 'pat', whichPats{p});
    fignames = whichFigs{p};
    if ~iscell(fignames)
      fignames = {fignames};
    end
    for f=1:length(fignames)
      fig{n} = getobj(pat, 'fig', fignames{f});
      
      n = n + 1;
    end
  end
  
  chan = pat.dim.chan;
  file = fullfile(resDir, [reportname '_' exp.subj(s).id]);

  for n=1:length(fig)
    try
			fig{n}.title = figtitles{n};
			catch
			fig{n}.title = 'figure';
		end
    newfig(n) = fig{n};
  end
  
	if ~isempty(strfind(title, '%s'))
		subjtitle = sprintf(title, exp.subj(s).id);
		else
		subjtitle = title;
	end

  report_by_channel(chan, newfig, file, subjtitle, compile);
end
