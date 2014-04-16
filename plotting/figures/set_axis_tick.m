function ticks = set_axis_tick(low, high, step)
%SET_AXIS_TICK   Set tick marks with a specified spacing.
%
%  ticks = set_axis_tick(low, high, step)

% lower bound always included
ticks = low;

if step < high
  % add the first step
  ticks = [ticks step:step:high];
  
  if (high - ticks(end)) > (step / 2)
    % add the upper bound if it's much higher than the last tick
    ticks = [ticks high];
  end
else
  % just upper and lower
  ticks = [ticks high];
end
