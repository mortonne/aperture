function [time2, bint] = timeBins(time1, params)
%[time, bint] = function(timeBins, params)

if ~exist('params', 'var')
  params = struct();
end

params = structDefaults(params, 'MSbins', {},  'MSbinlabels', {});

% get the current list of times
if isstruct(time1)
  avgtime = getStructField(time1, 'avg');
else
  avgtime = time1;
end

% make the new time bins
if isfield(params, 'MSbins') && ~isempty(params.MSbins)

  for t=1:length(params.MSbins)
    % define this bin
    bint{t} = find(avgtime>=params.MSbins(t,1) & avgtime<params.MSbins(t,2));
    
    % get ms value for each sample in the new time bin
    time2(t).MSvals = avgtime(bint{t});
    time2(t).avg = mean(time2(t).MSvals);
  end

elseif ~isempty(time1) % just copy info from time1

  if isstruct(time1)
    % copy the existing struct
    time2 = time1;
  else
    % create a new time struct
    for t=1:length(time1)
      time2(t).MSvals = time1(t);
      time2(t).avg = time1(t);
    end
  end
  
  % define the bins
  for t=1:length(time2)
    bint{t} = t;
  end
  
else % no time info; can't create the struct or bin it
  time2 = struct();
  bint = {};
  return
end

% update the time bin label
if ~isempty(params.MSbinlabels)
  time2(t).label = params.MSbinlabels{t};
else
  time2(t).label = sprintf('%d to %d ms', time2(t).MSvals(1), time2(t).MSvals(end));
end
