function mask = markArtifacts(events, timebins, artWindow)
%
%MARKARTIFACTS   

mask = false(length(events), size(timebins,1));

for e=1:length(events)
  wind = [events(e).artifactMS events(e).artifactMS+artWindow];
  isArt = 0;
  for t=1:size(timebins,1)
    if wind(1)>timebins(t,1) & wind(1)<timebins(t,2)
      isArt = 1;
    end
    mask(e,t) = isArt;
    if isArt & wind(2)<timebins(t,1)
      isArt = 0;
    end
  end
end
