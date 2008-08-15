function mask = markArtifacts(events, timebins, artWindow)
%MARKARTIFACTS   

mask = false(length(events), size(timebins,1));

for e=1:length(events)
  % get the time in ms of the first artifact after this event
  thisart = events(e).artifactMS;
  if thisart<0
    % no artifacts in this event
    continue
  end
  
  % set the window to mark as artifacty
  wind = [thisart thisart+artWindow];
  
  for t=1:size(timebins,1)
    startT = timebins(t,1);
    endT = timebins(t,2);
    
    % if this time window overlaps the artifact window at all, mark it
    if (startT>=wind(1) && startT<=wind(2)) || (endT>=wind(1) && endT<=wind(2))
      mask(e,t) = 1;
    end
  end
end
