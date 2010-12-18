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
%  confmat:  [class X class X chans X time X freq] matrix of
%            correlations between classifier output and class labels.

[n_iter, n_chans, n_time, n_freq] = size(res.iterations);
n_class = size(res.iterations(1).acts, 1);

confmat = NaN(n_class, n_class, n_chans, n_time, n_freq);

for j = 1:n_chans
  for k = 1:n_time
    for l = 1:n_freq
      guesses = [];
      desireds = [];
      
      for i = 1:n_iter
        perfmet = res.iterations(i,j,k,l).perfmet{1};
        guesses = [guesses perfmet.guesses];
        desireds = [desireds perfmet.desireds];
      end
      
      this_confmat = confusion(guesses, desireds, varargin{:});
      confmat(:,:,j,k,l) = this_confmat;
    end
  end
end

