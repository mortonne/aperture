function data = FRdata(events, trial_field)
%FRDATA   Create a free recall data struct from an events struct.
%   
%  data = FRdata(events, trial_field)
%
%  ASSUMPTIONS
%    * 'subject' field with subject id string
%    * List length is the same for all trials (because analysis 
%      scripts assume this, and data.listLength is expected to
%      be a scalar)
%    * events must contain a field with a scalar indicating the 
%      current list
%    * events must contain a 'type' field
%    * Presentation events correspond to type = 'WORD'
%    * Recall events correspond to type = 'REC_WORD'
%    * 'itemno' field in both presentation and recall events
%    * No item is presented more than once in a session
%
%  DATA FIELDS
%    subject       The index of where each subject was in the 
%                  sorted list of subject ids
%    subjid        Cell array of string ids for each subject
%    session       Session number
%    listLength    Number of items presented in each list
%    pres_itemnos  Presented wordpool item numbers
%    rec_itemnos   Recalled wordpool item numbers
%    recalls       Serial position of each recall;
%                   -1   Intrusion (see the intrusions field)
%                    0   Used for padding; indicates no recall
%                   >0   Correct recall, number gives serial position
%    times         Time (in ms) of each recall
%    intrusions    Gives information about intrusions:
%                    0   Correct recall (or no recall)
%                   -1   Extralist intrusion (XLI)
%                   >0   Prior-list intrusion (PLI); number indicates
%                        the number of lists back

% input checks
if ~isstruct(events)
  error('events must be a structure.');
elseif ~isfield(events,'subject')
  error('events must contain a ''subject'' field containing id strings.')
elseif ~isfield(events,'session')
  error('events must contain a ''session'' field with session numbers.')
elseif ~isfield(events,'itemno')
  error('events must contain an ''itemno'' field.')
elseif ~isfield(events,'type')
  error('events must contain a ''type'' field.')
elseif ~isfield(events,'rectime')
  warning('events has no ''rectime'' field; cannot get recall times.')
end
if ~exist('trial_field','var')
  trial_field = 'trial';
end

% get all subjects that we have recall events for
subjects = unique({events.subject});

data = [];
for s = 1:length(subjects)
  % get the id and number for this subject
  subj_id = subjects{s};
  subj_number = str2num(subj_id(isstrprop(subj_id, 'digit')));
  
  % get this subject's free recall events
  subj_events = events(strcmp({events.subject}, subj_id) ...
                       & ismember({events.type}, {'WORD' 'REC_WORD'}));
  
  % remove vocalizations
  subj_events = subj_events(~strcmp({subj_events.item}, 'VV'));
  
  % get a list of sessions that have both item presentation and recall
  % events
  sessions = unique([subj_events.session]);
  
  for sessno = sessions
    % get events for this session
    sess_events = subj_events([subj_events.session] == sessno);
    
    % get all trial numbers; assuming that if there are either
    % presentation or recall events, we want to include this trial in
    % the data matrix
    trials = [sess_events.(trial_field)];
    uniq_trials = unique(trials);
    
    % get presentation data
    item_pres = strcmp({sess_events.type}, 'WORD');
    if ~any(item_pres)
      % if this is thrown, somehow there are recall events for a session,
      % but no presentation events
      error('beh_toolbox:FRdata:noPresEvents', ...
            'No presentation events in %s session %d', subj_id, sessno)
    end
    pres_data = events2data(sess_events(item_pres), trials(item_pres), ...
                            uniq_trials);
    [n_trials, n_items] = size(pres_data.itemno);
    
    % get recall data
    recalls = strcmp({sess_events.type}, 'REC_WORD');
    rec_data = events2data(sess_events(recalls), trials(recalls), ...
                           uniq_trials);
    if ~any(recalls)
      % if we don't have any recall events in an entire session,
      % assume that it hasn't been annotated
      fprintf('Warning: no recall events in %s session %d.\n', ...
              subj_id, sessno)
      
      % create empty fields, with one empty column to allow keeping
      % track of trials properly
      fields = fieldnames(events);
      for i = 1:length(fields)
        f = fields{i};
        if iscellstr({events.(f)})
          rec_data.(f) = repmat({''}, size(rec_data.(f)));
        end
      end
    end

    % initialize this session's data
    d.subject = repmat(subj_number, [n_trials 1]);
    d.subjid = pres_data.subject;
    d.session = pres_data.session;
    d = vectorize_fields(d, {'subjid', 'session'});
    d.pres_items = pres_data.item;
    d.pres_itemnos = pres_data.itemno;
    d.rec_items = rec_data.item;
    d.rec_itemnos = rec_data.itemno;
    d.recalls = make_recalls_matrix(d.pres_itemnos, d.rec_itemnos);
    if isfield(rec_data, 'rectime')
      d.times = rec_data.rectime;
    end
    d.intrusions = create_intrusions(d.rec_itemnos, d.pres_itemnos, ...
                                     d.subject, d.session(:,1));
    % for now, assume that list length = number of columns, in case older
    % functions require this field
    d.listLength = n_items;

    % all fields on events structure are included, so custom fields
    % will also be converted to matrix format
    d.pres = pres_data;
    d.rec = rec_data;

    % concatenate with other sessions
    try
      % attempt to keep list length a scalar
      data = cat_data(data, d, {'listLength'}, true);
    catch
      data = cat_data(data, d);
    end
  end
end

if isempty(data)
  % it looks like we skipped all of the sessions. return an
  % empty structure.
  data = struct([]);
  return
end


function data = vectorize_fields(data, fields)
  for i = 1:length(fields)
    data.(fields{i}) = data.(fields{i})(:,1);
  end

