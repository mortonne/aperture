function subj = reject_subjects_eog(subj, ev_name, window, thresh)
%REJECT_SUBJECTS_EOG   Reject subjects with too many eye artifacts.
%
%  subj = reject_subjects_eog(subj, ev_name, window, thresh)
%
%  INPUTS:
%      subj:  vector of subject objects.
%
%   ev_name:  name of the events to search for blinks.
%
%    window:  window in milliseconds to search for blinks, of the form:
%             [min_ms max_mx]
%
%    thresh:  acceptable fraction of events containing a blink within
%             the window. Subjects with a blink fraction greater than
%             this will be excluded.
%
%  OUTPUTS:
%      subj:  vector of good subjects.

new_subj = [];
for this_subj=subj
  % get the time of the first artifact for each of this subject's
  % events
  events = get_mat(getobj(this_subj, 'ev', ev_name));
  art = [events.artifactMS];
  
  % find events with an artifact within the window
  bad = art > window(1) & art < window(2);
  blink_fraction = nnz(bad) / length(bad);
  fprintf('%s: %.4f\n', this_subj.id, blink_fraction)
  
  if blink_fraction < thresh
    % subject is OK
    new_subj = addobj(new_subj, this_subj);
  end
end

subj = new_subj;
