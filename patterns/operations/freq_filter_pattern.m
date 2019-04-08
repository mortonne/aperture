function pat = freq_filter_pattern(pat, freq_range, filt_type, varargin)
%FREQ_FILTER_PATTERN   Apply a filter to a pattern.
%
%  pat = freq_filter_pattern(pat, freq_range, filt_type, ...)
  
% options
def.order = 4;
def.buffer = [];
def.precision = '';
[opt, save_opt] = propval(varargin, def);

pat = mod_pattern(pat, @filter_pat, {freq_range, filt_type, opt}, save_opt);


function pat = filter_pat(pat, freq_range, filt_type, opt)

  samplerate = get_pat_samplerate(pat);
  if ~isempty(opt.buffer)
    buffer_samp = ms2samp(opt.buffer, samplerate);
    post_samp = patsize(pat.dim, 3) - 2 * buffer;
  else
    buffer_samp = 0;
    post_samp = patsize(pat.dim, 3);
  end

  pattern = get_mat(pat);
  if isempty(opt.precision)
    opt.precision = class(pattern);
  end
  
  [n_events, n_chan, n_time, n_freq] = size(pattern);
  new_pattern = NaN(n_events, n_chan, post_samp, n_freq, opt.precision);
  for i = 1:n_events
    for j = 1:n_chan
      for k = 1:n_freq
        % apply filter
        x = permute(pattern(i,j,:,k), [3 1 2 4]);
        y = buttfilt(double(x), freq_range, samplerate, filt_type, opt.order);

        % place in new pattern, without the buffer
        new_pattern(i,j,:,k) = y(buffer_samp+1:end-buffer_samp);
      end
    end
  end

  % set the pattern with the new matrix
  pat = set_mat(pat, new_pattern, 'ws');
  
  if buffer_samp > 0
    time = get_dim(pat.dim, 'time');
    time_filt = time(buffer_samp+1:end-buffer);
    pat.dim = set_dim(pat.dim, 'time', time_filt);
  end
