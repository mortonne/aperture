function waitforfiles(files, timeLimit)
%waitforfiles(files, timeLimit)

tic

wait = 1;
while wait
  wait = 0;
  
  for f=1:length(files)
    if ~exist(files{f}) | exist([files{f} '.lock'])
      wait = 1;
    end
  end
  
  if toc>=timeLimit
    error('Timeout waiting for files')
  end
  
end
