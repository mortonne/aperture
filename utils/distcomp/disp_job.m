function disp_job(job)
%DISP_JOB   Display the command window output of all tasks of a job.
%
%  disp_job(job)

more on

try
  for i = 1:length(job.tasks)
    fprintf('%s:\n', job.tasks(i).Name);
    disp(job.tasks(i).commandWindowOutput)
  end
catch err
  % if user quits before all output is shown
  more off
end
  
more off

