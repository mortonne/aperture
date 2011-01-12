function reportGenerator(contentStruct, outputFilename, ... %required inputs
    deleteWhenComplete, emailReport)                        %optional inputs

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

% This function uses latex to create a .pdf file
% corresponding to the content inside contentStruct.  Each entry of
% contentStruct describes a single section of a latex document, which may
% include text, figures, and figure captions.  This script creates a latex
% .tex file that includes this content, and compiles it into a .pdf file
% for you.
% 
% Inputs:
% 
%   contentStruct- This is a 1xN struct array, where N corresponds to the
%     number of sections in the output .pdf file.  Each individual structure
%     may contain these fields:
%
%     docTitle- document title.
% 	  title- Text describing the title of the section, which will be put in a
% 	    larger font in the pdf file
%     text1- Text that goes under the section title
% 	  figureName- The name of a graphics file that will appear in the pdf
%       file. May not contain .eps in conjunction with other formats.
%     figureWidth - in inches
%     figureCaption- The text of the caption that will
% 	    appear under the figure
%     text2- Text that goes under the figure.
% 
% 	Notes: Any of these fields can be missing or empty; in this case, this
% 	text is simply omitted from the pdf file.
% 
%   outputFilename- The name of the .pdf file that gets generated (omit
%     .pdf)
% 
%   deleteWhenComplete- This boolean variable indicates that all files should
%     be deleted after the pdf file is created. This includes the .tex file
%     that is processed by pdflatex and any images specified in
%     contentStruct.figureName.  If this variable is omitted, it defaults to
%     falses.
%
%   emailReport- optional. A string to e-mail the pdf after compilation.
%     May also be empty or not given.
%
% Example usage:
% 
% contentStruct(1).docTitle = 'Test document title';
% contentStruct(1).title = 'Test section 1 title';
% contentStruct(1).text1 = 'First block of text for section 1';
% contentStruct(1).figureName = 'demoFig.png';
% contentStruct(1).figureWidth = 5;
% contentStruct(1).figureCaption = 'demoFig.png caption';
% contentStruct(1).text2 = 'Second block of text for section 1';
% 
% reportGenerator(contentStruct,'testreport',true,'pcrutchl@psych.upenn.edu')
% 
% This usage creates a content structure with document title, section
% title, section text, figure with width 5 in and caption, and another
% block of text below. It is saved out to the current directory as
% testreport.pdf and a copy is e-mailed to pcrutchl. All auxiliary files
% (tex, dvi, log, aux) are deleted, as are the two .png images.
%
%
%
% See contentStruct.mat along with demo png figs in eeg_toolbox/plotting.




defaultFigWidth = 5; %inches

if nargin == 2
    deleteWhenComplete = false;
    emailReport = [];
elseif nargin == 3;
    emailReport = [];
end



% open the file
fid = fopen(outputFilename,'w');

% preamble

fprintf(fid,'\\documentclass[11pt]{article}\n');
%fprintf(fid,'\\usepackage{apacite}\n');
fprintf(fid,'\\usepackage{float}\n');
fprintf(fid,'\\usepackage{pxfonts}\n');
fprintf(fid,'\\usepackage{color}\n');
fprintf(fid,'\\usepackage{soul}\n');
fprintf(fid,'\\usepackage{setspace}\n');
fprintf(fid,'\\usepackage{graphicx}\n');
fprintf(fid,'\\usepackage{geometry} \n');
fprintf(fid,'\\usepackage{gensymb}\n');
fprintf(fid,'\\geometry{letterpaper,left=.5in,right=.5in,top=.5in,bottom=.8in}\n');


fprintf(fid,'\n');

% start the document
fprintf(fid,'\\begin{document}\n');
fprintf(fid,'\n');

for s = 1:length(contentStruct)
   
    if ~isempty(contentStruct(s).docTitle)
        fprintf(fid,'\\begin{center}\\section*{%s}\n',contentStruct(1).docTitle);
        fprintf(fid,'\\end{center}\n');
        fprintf(fid,'\n');
        if s > 1
            fprintf('Section %d has an unexpected docTitle field. Printing it anyway...',s);
        end
    end
    
    if ~isempty(contentStruct(s).title)
        fprintf(fid,'\\subsection*{%s}\n',contentStruct(s).title);
        fprintf(fid,'\n');
    end
    
    if ~isempty(contentStruct(s).text1)
        fprintf(fid,'%s\n',contentStruct(s).text1);
        fprintf(fid,'\n');
    end
    
    if ~isempty(contentStruct(s).figureName)
        if isempty(contentStruct(s).figureWidth)
            contentStruct(s).figureWidth = defaultFigWidth;
        end

        fprintf(fid,'\\begin{figure}[H]\n');
        fprintf(fid,'\\begin{center}\n');
        fprintf(fid,'\\includegraphics[width=%4.2fin]{%s}\n',contentStruct(s).figureWidth,contentStruct(s).figureName);
        fprintf(fid,'\\caption{%s}\n',contentStruct(s).figureCaption);
        fprintf(fid,'\\end{center}\n');
        fprintf(fid,'\\end{figure}\n');
        fprintf(fid,'\n');
    end
    
    if ~isempty(contentStruct(s).text2);
        fprintf(fid,'%s\n',contentStruct(s).text2);
        fprintf(fid,'\n');
    end
    
end

fprintf(fid,'\\end{document}');


if ~isempty(strfind([contentStruct.figureName],'.eps'))
    fprintf('compiling with latexdvipdf.m');
    pdf_file = pdflatex(outputFilename,'latexdvipdf');
else
    fprintf('compiling with pdflatex.m');
    pdf_file = pdflatex(outputFilename,'pdflatex');
end
    
fprintf('saved in %s.\n', pdf_file);

if ~isempty(emailReport)
    sendmail(emailReport,['Generated report: ' pdf_file],['Please find attached: PDF report ' pdf_file],pdf_file);
end
    

if deleteWhenComplete
    fprintf('deleting figures and TeX files...\n');
    delete([outputFilename '']);
    delete([outputFilename '.aux']);
    delete([outputFilename '.dvi']);
    delete([outputFilename '.log']);
    delete(contentStruct.figureName);
end

fprintf('done!\n');