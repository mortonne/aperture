function confmat = class_confusion(res, varargin)
%CLASS_CONFUSION   Calculate confusion matrices from classifier output.
%
%  confmat = class_confusion(res, ...)
%
%  INPUTS:
%     res:  a results structure from pattern classification.
%  Additional inputs are passed to confusion.
%
%  OUTPUTS:
%  confmat:  [actual-class X guessed-class X chans X time X freq] matrix
%            of rates for each (actual class, guessed class) condition.

[n_iter, n_chans, n_time, n_freq] = size(res.iterations);
n_class = size(res.iterations(1).acts, 1);

confmat = NaN(n_class, n_class, n_chans, n_time, n_freq);

for j = 1:n_chans
  for k = 1:n_time
    for l = 1:n_freq
      % get guesses and desireds across all cross-validation iterations
      [acts, targs] = get_class_stats(res.iterations(:,j,k,l));
      perf = perfmet_maxclass(acts, targs, struct);
      
      % calculate the confusion matrix
      this_confmat = confusion(perf.guesses, perf.desireds, varargin{:});
      confmat(:,:,j,k,l) = this_confmat;
    end
  end
end

