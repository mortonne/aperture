function events = addLagFields(events, param)
%ADDLAGFIELDS   Adds subsequent-clustering related fields to events.
%   EXP = ADDLAGFIELDS(EXP,PARAM)

% [all_ev] = addLagFields(exp,param)
%
% Loads all of the events tied to an exp structure and does some
% basic lag analysis, adding certain fields
% 
% param = [];
% param.itemstr = 'WORD';
% param.new_event_name = 'mod_events.mat';
%
% param.clust_thresh = 3;
%
% [ev] = addLagFields(exp);

if ~exist('param', 'var')
	param = struct();
end

param = structDefaults(param, 'itemstr','WORD', 'trialfield','trial');

% initialize the new fields
[events.prelag] = deal(NaN);
[events.postlag] = deal(NaN);

% step over sessions
sessions = unique([events.session]);
for session=sessions
  sess_ev = filterStruct(events, sprintf('session==%d', session));

  % step over lists
  lists = unique([sess_ev.(param.trialfield)]);
  lists = lists(lists>=0 & lists<100);
  for list=lists
    % get indices of the list events we need within the larger events struct
    listfilt = sprintf('session==%d & %s==%d', session, param.trialfield, list);
    study_ind = find(inStruct(events, sprintf('%s & strcmp(type,''%s'')', listfilt, param.itemstr)));
    rec_ind = find(inStruct(events, sprintf('%s & strcmp(type, ''REC_WORD'')', listfilt)));

    if isempty(study_ind)
      error('No study items found for list %d.', list);
    elseif isempty(rec_ind)
      error('No recall items found for list %d.', list);
    end

    % get the events
    study_ev = events(study_ind);
    rec_ev = events(rec_ind);

    % make sure recall events are sorted
    [times,order] = sort([rec_ev.rectime]);
    rec_ev = rec_ev(order);

    % get the presented serial position of each recall event
    study_itemno = [study_ev.itemno];
    for r = 1:length(rec_ev)
      % grab the original serial position
      s = find(study_itemno==rec_ev(r).itemno);
      
      if ~isempty(s)
        % add it to the recall event
        rec_ev(r).serialpos = study_ev(s).serialpos;
      else % intrusion
        rec_ev(r).serialpos = NaN;
      end
    end

    % get transition info
    lags = diff([rec_ev.serialpos]);
    % no lags of 0
    lags(lags==0) = NaN;
    
    % get prelag and postlag for each recall event
    postlag = [lags NaN];
    prelag = [NaN -lags];

    for r=1:length(rec_ev)
      s = rec_ev(r).serialpos;
      if isnan(s) % transitions to and from are undefined
        continue
      end

      % add lag info to study events
      study_ev(s).prelag = prelag(r);
      study_ev(s).postlag = postlag(r);

      % add lag info to recall events
      rec_ev(r).prelag = prelag(r);
      rec_ev(r).postlag = postlag(r);
    end

    % put the modified events back into the larger struct
    events(study_ind) = study_ev;
    events(rec_ind) = rec_ev;

  end % list
end % session
