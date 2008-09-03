function data = events2data(events)
%EVENTS2DATA   Convert an events struct to matrix format.
%   [DATA] = EVENTS2DATA(EVENTS) converts each field in EVENTS to
%   a trialsXitems matrix, each of which is saved under the same 
%   fieldname in DATA.
%
% assumptions: trial numbers in either 'trial' or 'list'
%

% get the field that contains trial info
fnames = fieldnames(events);
posstrialfields = {'list', 'trial'};

temp = intersect(posstrialfields, fnames);
trialfield = temp{1};

% get indices of trial starts
trials = [events.(trialfield)];
trialStart = find(diff([trials(1)+1 trials trials(end)+1]));
nTrial = length(trialStart)-1;

% get the length of each trial so we can initialize
data.LL = diff(trialStart)';
maxlen = max(data.LL);

for i=1:length(fnames)
  field = fnames{i};
  
  % get this field from the events struct
  fieldvec = getStructField(events, field);

  % initialize each data field
  if isnumeric(fieldvec)
    data.(field) = zeros(nTrial,maxlen);
    
    elseif iscell(fieldvec)
    data.(field) = cell(nTrial,maxlen);
  end
  
  % fill in the data struct
  for j=1:nTrial
    trialInd = [trialStart(j):trialStart(j+1)-1];
    data.(field)(j,1:length(trialInd)) = fieldvec(trialInd);
  end
end

% vectorize fields that don't require a matrix
data = vectorize(data,{'subject','session','list','trial'});

function data = vectorize(data,fields)
  
  for i=1:length(fields)
    if isfield(data,fields{i})
      f = data.(fields{i});
      data.(fields{i}) = f(:,1);
    end
  end
