function elocs = read_tal(subject, tal_file, channels)
%READ_TAL   Read electrode locations from the Talairach database.
%
%  elocs = read_tal(subject, tal_file, channels)
%
%  INPUTS:
%   subject:  string subject identifier. Must match the ID used in
%             the Talairach database.
%
%  tal_file:  path to the MAT-file output by the Talairach database
%             function. 
%
%  channels:  (optional) vector of channel numbers to include.

% critical fields to grab
f = {'x' 'y' 'z' ...
     'Loc1' 'Loc2' 'Loc3' 'Loc4' 'Loc5' 'Loc6' ...
     'isGood' 'montage'};

% load the talairach database
tal = getfield(load(tal_file, 'events'), 'events');

% does the tal database has channels for this subject? 
tal = tal([strcmp({tal.subject}, subject)]);
if isempty(tal)
  error('Subject "%s" has no entries in the tal database.', subject);
end

if nargin < 3
  % no channels specified; use all
  channels = [tal.channel];
  elocs = rmfield(tal, setdiff(fieldnames(tal), f));
  [elocs.tal] = deal(1);
  
else
  elocs = [];
  for i = 1:length(channels)
    tal_chan = tal([tal.channel] == channels(i));
    
    % error checking
    if isempty(tal_chan)
      elocs(i).tal = 0;
      fprintf('Database missing chan %d.\n', channels(i));
      continue
    elseif length(tal_chan) > 1
      error('Database has multiple entries for a single channel.');
    end
    
    elocs(i).tal = 1;
    % pull over the relevant fields
    for j = 1:length(f)
      elocs(i).(f{j}) = tal_chan.(f{j});
    end
  end
end

% add necessary standard fields
c = num2cell(channels);
[elocs.number] = c{:};
c = cellfun(@num2str, c, 'UniformOutput', false);
[elocs.label] = c{:};

