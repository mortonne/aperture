function [time2, bint] = timeBins(time1, params)
%[time, bint] = function(timeBins, params)

if ~exist('time1', 'var')
  time1 = [];
end
if ~exist('params', 'var')
  params = struct();
end

params = structDefaults(params, 'MSbins', {},  'MSbinlabels', {});

% make the new time bins
if ~isempty(params.MSbins)

  % get the current list of times
  avgtime = [time1.avg];
  
  if length(params.MSbins)==1
    stepSize = params.MSbins;
    nSteps = fix((avgtime(end)-avgtime(1))/stepSize);
    startMS = avgtime(1);
    for i=1:nSteps
      params.MSbins(i,1) = startMS;
      endMS = startMS + stepSize;
      params.MSbins(i,2) = endMS;
      startMS = endMS;
    end
  end
  
  for t=1:length(params.MSbins)
    % define this bin
    bint{t} = find(avgtime>=params.MSbins(t,1) & avgtime<params.MSbins(t,2));
    
    % get ms value for each sample in the new time bin
    time2(t).MSvals = avgtime(bint{t});
    time2(t).avg = mean(time2(t).MSvals);
    
    % update the time bin label
    if ~isempty(params.MSbinlabels)
      time2(t).label = params.MSbinlabels{t};
    else
      time2(t).label = sprintf('%d to %d ms', time2(t).MSvals(1), time2(t).MSvals(end));
    end
  end

elseif ~isempty(time1) % just copy info from time1

  % copy the existing struct
  time2 = time1;
  
  % define the bins
  for t=1:length(time2)
    bint{t} = t;
  end
  
else % no time info; can't create the struct or bin it
  time2 = init_time();
  bint = {};
end
