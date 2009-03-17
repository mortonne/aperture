function events = addLagFields(events, param)
%ADDLAGFIELDS   Add subsequent-clustering related fields to events.
%
%  events = addLagFields(events, param)
%
%  Use this function to add information to recall events about
%  transitions to and from each recalled item.
%  
%  Serial position is derived from the study events in each list; 
%  so, if you have removed some study events from a list but left 
%  others, that will affect the lag calculated for recall events 
%  for that list.
%
%  INPUTS:
%   events:  an events structure. Required fields:
%             'session'   session number
%
%             'trial'     trial number
%
%             'type'      string indicating the type of event. Must
%                         include WORD and REC_WORD.
%
%             'mstime'    OPTIONAL: experiment time in milliseconds. 
%                         Used to make sure events are in the correct
%                         order.
%
%    param:  structure specifying options. See below.
%
%  OUTPUTS:
%   events:  events structure with new fields:
%             prelag - lag to the word recalled before this one
%             postlag - lag to the word recalled next
%             outputpos - output position during recall, counting
%                         only REC_WORD events.
%
%  PARAMS:
%     itemstr:  value of the 'type' field for item presentations
%               default: 'WORD'
%
%  trialfield:  name of the field that contains the trial number
%               default: 'trial'

% input checks
if ~exist('events','var')
  error('You must pass an events structure.')
  elseif ~isstruct(events)
  error('Events must be a structure.')
end
if ~exist('param', 'var')
	param = struct();
end
param = structDefaults(param, 'itemstr','WORD', 'trialfield','trial');

% initialize the new fields
[events.prelag] = deal(NaN);
[events.postlag] = deal(NaN);
[events.outputpos] = deal(NaN);

% session numbers
sessions = unique([events.session]);
for session=sessions
  % get events for this session
  sess_ev = events([events.session]==session);

  % trial numbers
  lists = unique([sess_ev.(param.trialfield)]);
  lists = lists(lists>=0 & lists<100);
  for list=lists
    % get a logical vector that is true for this list's events
    list_mask = [events.session]==session & [events.(param.trialfield)]==list;
    
    % get indices within the entire events structure for study and recall
    % events for this list
    study_ind = find(list_mask & strcmp({events.type}, param.itemstr));
    rec_ind = find(list_mask & strcmp({events.type}, 'REC_WORD'));

    % we need both study and recall events
    if isempty(study_ind)
      error('No study items found for list %d.', list);
      elseif isempty(rec_ind)
      error('No recall items found for list %d.', list);
    end

    % get the events
    study_ev = events(study_ind);
    rec_ev = events(rec_ind);

    % make sure events are sorted
    if isfield(study_ev,'mstime')
      [times, order] = sort([study_ev.mstime]);
      study_ev = study_ev(order);
    end
    if isfield(rec_ev,'mstime')
      [times, order] = sort([rec_ev.mstime]);
      rec_ev = rec_ev(order);
    end

    % get the presented serial position of each recall event
    rec_serial_pos = NaN(1,length(rec_ev));
    for r=1:length(rec_ev)
      % index of the original presentation
      s = find([study_ev.itemno]==rec_ev(r).itemno);
      if ~isempty(s)
        % this was a correct recall; add this serial position
        % to the list
        rec_serial_pos(r) = s;
      end
    end

    % get transition info
    lags = diff([rec_serial_pos]);
    % no lags of 0
    lags(lags==0) = NaN;
    
    % get prelag and postlag for each recall event
    postlag = [lags NaN];
    prelag = [NaN -lags];

    % serial position of all recalled items
    serial_pos = unique(rec_serial_pos(~isnan(rec_serial_pos)));
    
    for s=serial_pos
      % get all recalls for this serial position
      recalls = find(rec_serial_pos==s);
      
      % if this item was repeated, take the first recall
      r = recalls(1);
      
      % add lag info to study events
      study_ev(s).prelag = prelag(r);
      study_ev(s).postlag = postlag(r);
      study_ev(s).outputpos = r;
      
      % add lag info to recall events
      rec_ev(r).prelag = prelag(r);
      rec_ev(r).postlag = postlag(r);
      rec_ev(r).outputpos = r;
    end

    % put the modified events back into the larger structure
    events(study_ind) = study_ev;
    events(rec_ind) = rec_ev;
  end
end
