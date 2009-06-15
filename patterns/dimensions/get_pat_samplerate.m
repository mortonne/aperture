function samplerate = get_pat_samplerate(pat)
%GET_PAT_SAMPLERATE   Return the samplerate of a pattern.
%
%  samplerate = get_pat_samplerate(pat)

ms = [pat.dim.time.avg];
step_size = unique(diff(ms));
if length(step_size)>1
  error('Samplerate varies.')
end

samplerate = 1000/step_size;
