function confmat = class_confusion(res, conf_type)
%CLASS_CONFUSION   Calculate confusion matrices from classifier output.
%
%  confmat = class_confusion(res, conf_type)
%
%  INPUTS:
%        res:  a results structure from pattern classification.
%
%  conf_type:  confusion measure to calculate:
%               'rate'  - response rate for each condition. (default)
%               'xcorr' - cross-correlation. Correlation of each output
%                         unit with the actual values.
%
%  OUTPUTS:
%  confmat:  [actual-class X guessed-class X chans X time X freq] matrix
%            of rates for each (actual class, guessed class) condition.

% input checks
if ~exist('conf_type', 'var')
  conf_type = 'rate';
end

[n_iter, n_chans, n_time, n_freq] = size(res.iterations);
n_class = size(res.iterations(1).acts, 1);

confmat = NaN(n_class, n_class, n_chans, n_time, n_freq);

for j = 1:n_chans
  for k = 1:n_time
    for l = 1:n_freq
      % get guesses and desireds across all cross-validation iterations
      [acts, targs] = get_class_stats(res.iterations(:,j,k,l));
      
      switch conf_type
       case 'rate'
        perf = perfmet_maxclass(acts, targs, struct);
        
        % calculate the confusion matrix
        this_confmat = confusion(perf.guesses, perf.desireds);
        
       case 'xcorr'
        this_confmat = xcorr(acts, targs);
      end
      
      confmat(:,:,j,k,l) = this_confmat;
    end
  end
end


function confmat = xcorr(acts, targs)

% remove NaN 
missing = all(isnan(acts), 1);
acts = acts(:,~missing);
targs = targs(:,~missing);

% targs (right answer) X acts (guess)
n_conds = size(acts, 1);
confmat = NaN(n_conds, n_conds);
for i = 1:n_conds
  for j = 1:n_conds
    confmat(i,j) = corr(targs(i,:)', acts(j,:)');
  end
end

