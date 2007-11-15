function eeg = make_regressors(eeg, regParams)
%eeg = make_regressors(eeg, regParams)

params = eeg.params;

% prepare dir for the regressors
if ~exist(fullfile(eeg.resDir, 'data'))
  mkdir(fullfile(eeg.resDir, 'data'))
end

for s=1:length(eeg.subj)

  % prepare regressors file
  eeg.subj(s).regFile = fullfile(eeg.resDir, 'data', [eeg.subj(s).id '_reg.mat']);
  
  % get all events for this subject, apply the filter
  subj_events = [];
  for n=1:length(eeg.subj(s).sess)
    events = loadEvents(eeg.subj(s).sess(n).eventsFile, params.replace_eegFile);
    subj_events = [subj_events filterStruct(events, params.eventFilter)];
  end 
  
  for r=1:length(regParams)
    
    % initialize this regressor
    reg(r).name = regParams{r}.field;
    if isfield(regParams{r}, 'continuous') && regParams{r}.continuous
      reg(r).continuous = 1;
    else
      reg(r).continuous = 0;
    end
    
    % get the string to filter the events struct
    if isfield(regParams{r}, 'condstr')
      reg(r).condstr = regParams{r}.condstr;
      
    elseif ~reg(r).continuous
      condvals = unique(getStructField(subj_events, reg(r).name));
      if iscell(condvals)
	for i=1:length(condvals)
	  reg(r).condstr{i} = ['strcmp(' reg(r).name ',''' condvals{i} ''')'];
	end
	
      else
	for i=1:length(condvals)
	  reg(r).condstr{i} = [reg(r).name '==' num2str(condvals(i))];
	end
      end
    
    else 
      reg(r).condstr = {};
    end
    
    % make the regressor vector
    reg(r).vec = getStructField(subj_events, reg(r).name);
    
    % make the regressor logical matrix, if categorical
    if ~reg(r).continuous
      reg(r).mat = logical(zeros(length(subj_events), length(reg(r).condstr)));
      for i=1:length(reg(r).condstr)
	reg(r).mat(:,i) = inStruct(subj_events, reg(r).condstr{i});
      end
    else
      reg(r).mat = [];
    end
    
  end % regressors
  
  % save the regressors for this subject
  save(eeg.subj(s).regFile, 'reg');
  save(fullfile(eeg.resDir, 'eeg.mat'), 'eeg');
  
end % subj