function [chan2, binc] = chanBins(chan1, params)
%[chan2, binc] = chanBins(chan1, params)

if ~exist('params', 'var')
  params = struct();
end

params = structDefaults(params, 'chanbins', {},  'chanbinlabels', {})

if ~isempty(params.chanbins)
  for c=1:length(params.chanbins)
    % define the new channel bins
    if ~iscell(params.chanbins)
      binc{c} = params.chanbins(c);
    elseif isnumeric(params.chanbins{c})
      binc{c} = find(inStruct(chan1, 'ismember(number, varargin{1})', params.chanbins{c}));
    elseif iscell(params.chanbins{c})
      binc{c} = find(inStruct(chan1, 'ismember(region, varargin{1})', params.chanbins{c}));
    elseif isstr(params.chanbins{c})
      binc{c} = find(inStruct(chan1, 'strcmp(region, varargin{1})', params.chanbins{c}));
    end
    theseChans = chan1(binc{c});
    
    % update the channel labels
    chan2(c).number = getStructField(theseChans, 'number');
    chan2(c).region = getStructField(theseChans, 'region');
    if ~isempty(params.chanbinlabels)
      chan2(c).label = params.chanbinlabels{c};
    elseif length(unique({chan2.region}))==length(chan2)
      chan2(c).label = chan2(c).region;
    else
      chan2(c).label = num2str(chan2(c).number);
    end
    
  end
  
else
  for c=1:length(chan1)
    binc{c} = c;
  end
  chan2 = chan1;
end
