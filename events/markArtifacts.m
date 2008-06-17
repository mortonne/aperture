function mask = rmArtifacts(events, time, artWindow)
%mask = rmArtifacts(events, time, artWindow)

mask = false(length(events), length(time));

for e=1:length(events)
  wind = [events(e).artifactMS events(e).artifactMS+artWindow];
  isArt = 0;
  for t=1:length(time)
    if wind(1)>time(t).MSvals(1) & wind(1)<time(t).MSvals(end)
      isArt = 1;
    end
    mask(e,t) = isArt;
    if isArt & wind(2)<time(t).MSvals(end)
      isArt = 0;
    end
  end
end
