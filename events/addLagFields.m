function [all_ev] = addLagFields(eeg,param)
% [all_ev] = addLagFields(eeg,param)
%
% Loads all of the events tied to an eeg structure and does some
% basic lag analysis, adding certain fields
% 
% param = [];
% param.itemstr = 'WORD';
%
% [ev] = addLagFields(eeg);

itemstr = getValFromStruct(param,'itemstr','WORD');

% label recall events by the lag of the transition
all_ev = [];

% step over subjects
for i = 1:length(eeg.subj)
  
  % step over sessions
  for j = 1:length(eeg.subj(i).sess)
    % load events
    ev = loadEvents(eeg.subj(i).sess(j).eventsFile);
    for k = 1:length(ev)
      ev(k).prelag = -999;
      ev(k).minlag = -999;
    end
    % step over lists
    % how many lists
    list_id = getStructField(ev,'list');
    nlists = max(list_id);
    for k = 1:nlists
      
      evalstr1 = strcat('list==',num2str(k));
      evalstr2 = 'strcmp(type,''REC_WORD'')';
      evalstr3 = strcat('strcmp(type,''',itemstr,''')';
      evalstr4 = 'recalled == 1';
      evalstr5 = 'intrusion == 0';
      
      evalstrS = strcat([evalstr1,' & ',evalstr3,' & ',evalstr4]);
      evalstrR = strcat([evalstr1,' & ',evalstr2,' & ',evalstr5]);

      % grab this list's study and recall events
      [temp,study_ind] = filterStruct(ev,evalstrS);
      [temp,rec_ind] = filterStruct(ev,evalstrR);

      these_rec = find(rec_ind);
      these_study = find(study_ind);
      
      % sort the recall events
      [times,order] = sort(getStructField(ev(rec_ind),'rectime'));
      % grab all the itemnos
      [rec_itemnos] = getStructField(ev(these_rec(order)),'itemno');
      % get the study order of the itemnos
      [study_serpos] = getStructField(ev(study_ind),'serialpos');
      [study_itemno] = getStructField(ev(study_ind),'itemno');
      
      % step through the recall events
      for r = 1:length(order)
	% grab the original serial position
	sind = find(study_itemno==rec_itemnos(r));
	% add it to the recall event
	ev(these_rec(order(r))).serialpos = study_serpos(sind);
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
	  ev(these_rec(r)).prelag = abs(lags(r-1));
	else
	  ev(these_rec(r)).prelag = -999;
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
	ev(these_study(sind)).minlag = minlag;
	
      end
      	
    end % k list
    
    % concatenate into a big events struct
    all_ev = [all_ev ev];
    
  end
  
end








