function pat = post_timebin(pat)

step_size = unique(diff([pat.dim.time.avg]));
if length(step_size)>1
  stepper = (pat.dim.time(end-1).avg)- ...
            (pat.dim.time(end-2).avg);
  pat.dim.time(end).avg = pat.dim.time(end-1).avg+stepper;
end
