function [all_ev] = addLagFields(exp,param)
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

itemstr = getValFromStruct(param,'itemstr','WORD');
% if this or smaller, then it is counted as clustered
clust_thresh = getValFromStruct(param,'clust_thresh',3);
new_event_name = getValFromStruct(param,'new_event_name','mod_events.mat');

% label recall events by the lag of the transition
all_ev = [];

% step over subjects
for i = 1:length(exp.subj)
  
  % step over sessions
  for j = 1:length(exp.subj(i).sess)
    % load events for this session
    ev = loadEvents(exp.subj(i).sess(j).eventsFile);
    for k = 1:length(ev)
      ev(k).prelag = -999;
      ev(k).minlag = -999;
      ev(k).subclust = -999;
    end
    % step over lists
    % how many lists
    list_id = getStructField(ev,'list');
    nlists = max(list_id);
    for k = 1:nlists
      list_ev = filterStruct(ev, ['list==' num2str(k)]);
      
      study_ind = inStruct(list_ev, 'strcmp(type,%s) & recalled==1', itemstr);
      rec_ind = inStruct(list_ev, sprintf('strcmp(type,''REC_WORD'') & intrusion==0'));

      these_rec = find(rec_ind);
      these_study = find(study_ind);
      
      % sort the recall events
      [times,order] = sort(getStructField(list_ev(rec_ind),'rectime'));
      % grab all the itemnos
      [rec_itemnos] = getStructField(list_ev(these_rec(order)),'itemno');
      % get the study order of the itemnos
      [study_serpos] = getStructField(list_ev(study_ind),'serialpos');
      [study_itemno] = getStructField(list_ev(study_ind),'itemno');
      
      % step through the recall events
      for r = 1:length(order)
	% grab the original serial position
	sind = find(study_itemno==rec_itemnos(r));
	% add it to the recall event
	list_ev(these_rec(order(r))).serialpos = study_serpos(sind);
	rec_serpos(r) = study_serpos(sind);
      end
      
      % calculate lag for each transition
      lags = diff(rec_serpos);	
      lag_ind = 1:length(lags);
      % aside from the terminal items, each item has two
      % associated lags.
      for r=1:length(these_rec)
	
	% tag each recall event with the lag to the preceding item
        % in the recall sequence
	if ismember(r-1,lag_ind)
	  list_ev(these_rec(r)).prelag = abs(lags(r-1));
	else
	  list_ev(these_rec(r)).prelag = -999;
	end
	
	% which lag values correspond to this recall item
	% accounting for the terminal items
	lagset = r-1:r;
	lagset = lagset(ismember(lagset,lag_ind));
	these_lags = lags(lagset);
	minlag = min(abs(these_lags));
		
	% find the corresponding study event
	sind = find(study_itemno==rec_itemnos(r));
	% add minlag to the study event
	list_ev(these_study(sind)).minlag = minlag;
	if minlag <= clust_thresh
	  list_ev(these_study(sind)).subclust = 1;
	else
	  list_ev(these_study(sind)).subclust = 0;
	end
	
      end
      
    end % k list
    
    % save modified events to disk
    pathstr = fileparts(eeg.subj(i).sess(j).eventsFile);
    events = list_ev;
    save(fullfile(pathstr,new_event_name),'events');
    
    % concatenate into a big events struct
    all_ev = [all_ev ev];
    
  end % j session
  
end








