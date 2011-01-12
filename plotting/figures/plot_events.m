function h = plot_events(events, opt)
%PLOT_EVENTS   Visualize information in an events structure.
%   H = PLOT_EVENTS(EVENTS,OPT) makes a plot of the information contained
%   in the EVENTS structure, using options specified in the OPT structure.
%
%   OPT is a vector structure.  Each element of OPT specifies options
%   for one set of lines, regions, or labels.
%     'field'   Name of a field of the events struct
%     'type'    Type of plot to make
%     'params'  Additional parameters specific to the plot type
%

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

if ~exist('opt','var')
  opt = struct;
end

clf
sym = {'b','g','r','c','m','y','k'};
fillcolor = {[.4 .4 .4], [.2 .2 .2]};

% get the start time for each event
times = [events.mstime];

ytemp = [0 1];

regionCount = 1;
for i=1:length(opt)
  % fill in missing fields with default values
  options = structDefaults(opt(i), 'field','type', 'type','label',  'params', {});

  % get the field to plot
  if isstr(options.field)
    f = getStructField(events, options.field);
  end

  switch options.type
    case 'line'
    h{i} = lines(times, ytemp, f, options.field, sym, options.params);
    
    case 'region'
    if isfield(events, options.field)
      ends = [events.(options.field)] + times;
      else
      ends = ones(size(times)).*options.field + times;
    end
    h{i} = regions(times,ends,ytemp,fillcolor{regionCount});
    regionCount = regionCount + 1;
    
    case 'label'
    % set height for each sucessive label
    step = range(ytemp)/(length(f)-1);
    texty = ytemp(1)+step:step:ytemp(2);
    
    %h{i} = labels(times, f, texty(i));
    h{i} = labels(times, f, .5);    
    otherwise
    error('Invalid plot type.')
    
  end

end

function h = lines(times, marky, field, fieldname, colors, params)

  uf = unique(field(~isnan(field)));

  for i=1:length(uf)
    val = uf(i);
    ind = find(field==val);

    x = repmat(times(ind),2,1);
    y = repmat(marky',1,length(ind));
    h{i} = line(x,y,'Color',colors{i},params{:});
    hl(i) = h{i}(1);

    label{i} = sprintf('%s %d', fieldname, val);
  end

  legend(hl,label{:},'Location','NorthWest')
%endfunction

function h = regions(starts,ends,marky,fillcolor)
  nRegions = length(starts);
  for i=1:nRegions
    l2r = [starts(i) ends(i)];
    r2l = fliplr(l2r);

    region_x = [l2r r2l];
    region_y = [repmat(marky(1),1,length(l2r)) repmat(marky(2),1,length(r2l))];

    h = fill(region_x, region_y, fillcolor);
    set(h, 'edgecolor', fillcolor)
    hold on
  end
%endfunction

function h = labels(times, field, texty)
  uf = unique(field);

  for i=1:length(uf)
    if iscell(uf)
      val = uf{i};
      ind = find(strcmp(field,val));
      label = strrep(val, '_', '\_');
      
      else
      val = uf(i);
      ind = find(field==val);
      label = num2str(val);
    end
    
    x = times(ind);
    y = repmat(texty,1,length(ind));
    h = text(x,y,label,'BackgroundColor','w', 'EdgeColor','k', 'HorizontalAlignment','center','FontSize',10);

  end
%endfunction
