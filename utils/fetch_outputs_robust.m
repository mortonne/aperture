function o = fetch_outputs_robust(job, timeout)
%FETCH_OUTPUTS_ROBUST   Fetch outputs with multiple tries until timeout.
%
%  o = fetch_outputs_robust(job, timeout)

if nargin < 2
  timeout = 60;
end

finished = false;
tic
while ~finished
  try
    o = fetchOutputs(job);
    finished = true;
  catch err
    if toc > timeout
      rethrow(err)
    end
  end
end

