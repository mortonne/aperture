function subj = create_diff_pattern(subj, old_pat_name, new_pat_name, params)

subj = apply_to_pat(subj, old_pat_name, @modify_pattern, ...
                    {struct('save_mats', true, 'overwrite', true), ...
                    new_pat_name}, 0);

% get the difference of your channels
subj = apply_to_pat(subj, new_pat_name, @get_chandiffs, {params});




%% ZACH
%%%%%%%%% Copied from get_eog
  function pat = get_chandiffs(pat, params)
  
  channels = [pat.dim.chan.number];
  chan_ind = [find(channels==params.chans(1)) find(channels==params.chans(2))];
  if length(chan_ind)~=2
    error('channels not found.')
  end
  
  pattern = load_pattern(pat);
  pattern = pattern(:,chan_ind(1),:,:) - pattern(:,chan_ind(2),:,:);
  pat.mat = pattern;
  
  %need to define region_label above
  %start HACK
  region_label = 'eog';
  %end HACK
  pat.dim.chan = struct('number',params.chans,'region', ...
                        region_label,'label',pat.source);
  
  pat = move_obj_to_hd(pat);
  
%endfunction