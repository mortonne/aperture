function exp = addLagFields(exp, param, evname)
%
%ADDLAGFIELDS   Adds subsequent-clustering related fields to events.
%   EXP = ADDLAGFIELDS(EXP,PARAM,EVNAME)

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

param = structDefaults(param, 'itemstr', 'WORD',  'trialfield', 'trial',  'clust_thresh', 3,  'evname', 'events',  'overwrite', 1,    'lock', 0);

% step over subjects
for subj=exp.subj
	fprintf('\nProcessing %s...', subj.id)

	% load the events
	ev1 = getobj(subj, 'ev', param.evname);
	load(ev1.file);

	ev2 = ev1;
	if exist('evname', 'var')
		% save the results in a new ev object
		ev2.name = evname;
		ev2.file = fullfile(fileparts(ev1.file), sprintf('%s_%s.mat', evname, subj.id));

		% update exp
		exp = update_exp(exp, 'subj', subj.id, 'ev', ev2);
	end

	% prepare the events file
	if prepFiles({}, ev2.file, param)~=0
		continue
	end

	% initialize the new fields
	for k=1:length(events)
		events(k).prelag = -999;
		events(k).minlag = -999;
		events(k).subclust = -999;
	end

	% step over sessions
	sessions = unique(getStructField(events, 'session'));
	for j = 1:length(sessions)
		sess_ev = filterStruct(events, sprintf('session==%d', sessions(j)));

		% step over lists
		lists = unique(getStructField(sess_ev, param.trialfield));
		lists = lists(lists>=0 & lists<100);
		for k = 1:length(lists)

			% get indices of the list events we need within the larger events struct
			listfilt = sprintf('session==%d & %s==%d', sessions(j), param.trialfield, lists(k));
			study_ind = find(inStruct(events, sprintf('%s & strcmp(type,''%s'') & recalled==1', listfilt, param.itemstr)));
			rec_ind = find(inStruct(events, sprintf('%s & strcmp(type, ''REC_WORD'') & intrusion==0', listfilt)));

			if length(study_ind)==0
				error(sprintf('No study items found for list %d.', lists(k)));
				elseif	length(rec_ind)==0
				error(sprintf('No recall items found for list %d.', lists(k)));
			end

			% get the events
			study_ev = events(study_ind);
			rec_ev = events(rec_ind);

			% sort the recall events
			[times,order] = sort(getStructField(rec_ev, 'rectime'));
			rec_ev = rec_ev(order);

			% grab all the itemnos
			[rec_itemnos] = getStructField(rec_ev, 'itemno');
			% get the study order of the itemnos
			[study_serpos] = getStructField(study_ev, 'serialpos');
			[study_itemno] = getStructField(study_ev, 'itemno');

			% step through the recall events
			for r = 1:length(rec_ev)
				% grab the original serial position
				sind = find(study_itemno==rec_itemnos(r));
				% add it to the recall event
				rec_ev(r).serialpos = study_serpos(sind);
				rec_serpos(r) = study_serpos(sind);
			end

			% calculate lag for each transition
			lags = diff(rec_serpos);	
			lag_ind = 1:length(lags);
			% aside from the terminal items, each item has two
			% associated lags.
			for r=1:length(rec_ev)

				% tag each recall event with the lag to the preceding item
				% in the recall sequence
				if ismember(r-1,lag_ind)
					rec_ev(r).prelag = abs(lags(r-1));
					else
					rec_ev(r).prelag = -999;
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
				study_ev(sind).minlag = minlag;
				if minlag <= param.clust_thresh
					study_ev(sind).subclust = 1;
					else
					study_ev(sind).subclust = 0;
				end

			end

			% put the modified events back into the larger struct
			events(study_ind) = study_ev;
			events(rec_ind) = rec_ev;

		end % k list

	end % j session

	save(ev2.file, 'events');
	fprintf('New events saved.');
end % i subject
