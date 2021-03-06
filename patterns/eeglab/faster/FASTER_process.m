function EEG=FASTER_process(option_wrapper,log_file)

% Copyright (C) 2010 Hugh Nolan, Robert Whelan and Richard Reilly, Trinity College Dublin,
% Ireland
% nolanhu@tcd.ie, robert.whelan@tcd.ie
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

EEG = [];
try
    tic
    o = option_wrapper.options;
    
    try
        % set new options currently not supported by the GUI
        epoch_overlap = o.epoch_options.epoch_overlap;
        amp_diff_thresh = ...
            o.epoch_interp_options.rejection_options.amp_diff_thresh;
        bad_epoch_thresh = ...
            o.epoch_interp_options.rejection_options.bad_epoch_thresh;
        n_max_pca = o.ica_options.n_max_pca;
    catch
        epoch_overlap = true;
        amp_diff_thresh = 150;
        bad_epoch_thresh = 12;
        n_max_pca = 128;
    end
      
    %%%%%%%%%%%%%%%%
    % File options %
    %%%%%%%%%%%%%%%%
    % 1 File name including full path (string)
    % 2 Reference channel (integer > 0)
    % 3 Number of data channels (integer > 0)
    % 4 Number of extra channels (integer > 0)
    % 5 Channel locations file including full path (string)
    % 6 Save options (cell)
    %%%%%%%%%%%%%%%%

    using_ALLEEG = o.file_options.using_ALLEEG;
    save_options = o.save_options;
    cutoff_markers = o.file_options.cutoff_markers;

    % start of log
    c = clock;
    months = {'Jan' 'Feb' 'Mar' 'Apr' 'May' 'Jun' ...
              'Jul' 'Aug' 'Sep' 'Oct' 'Nov' 'Dec'};
    fprintf(log_file, '\n%d/%s/%d %d:%d:%d\n', c(3), months{c(2)}, ...
            c(1), c(4), c(5), round(c(6)));
    fprintf(log_file, '%.2f - Opened log file.\n', toc);

    %%%%%%%%%%%%%%%%%%%%%%
    % File setup section %
    %%%%%%%%%%%%%%%%%%%%%%

    % load the file, get dir to save results in
    [EEG, filepath, filename] = prep_files(o, log_file);
        
    % unpack channel information
    ref_chan = o.channel_options.ref_chan;
    eeg_chans = o.channel_options.eeg_chans;
    if eeg_chans == 0
        eeg_chans = [];
    end
    ext_chans = o.channel_options.ext_chans;
    if ext_chans == 0
        ext_chans = [];
    end
    do_reref = o.channel_options.do_reref;
    if ~do_reref
        ref_chan = [];
    end
    channel_locations_file = o.file_options.channel_locations;
    
    % remove channels that we aren't using
    EEG = pop_select(EEG, 'nochannel', length(eeg_chans) + ...
                     length(ext_chans) + 1:size(EEG.data, 1));
    
    % set the reference channel
    if do_reref
        if max(EEG.data(ref_chan,:)) == 0 && min(EEG.data(ref_chan,:)) == 0
            fprintf(log_file, '%.2f - Reference channel %d is already zeroed. Data was not re-referenced.\n',toc,ref_chan);
        elseif o.ica_options.keep_ICA && ~isempty(EEG.icaweights)
            fprintf(log_file,'%.2f - Data was not re-referenced to maintain existing ICA weights. Bad channel detection may be ineffective.\n',toc,ref_chan);
        else
            % reference to a new channel
            EEG = h_pop_reref(EEG, ref_chan, 'exclude', ext_chans, ...
                              'keepref', 'on');
        end
    end
    
    EEG = eeg_checkset(EEG);

    % Check if channel locations exist, and if not load them from disk.
    if (~isfield(EEG.chanlocs,'X') || ~isfield(EEG.chanlocs,'Y') || ~isfield(EEG.chanlocs,'Z') || isempty(EEG.chanlocs)) || isempty([EEG.chanlocs(:).X]) || isempty([EEG.chanlocs(:).Y]) || isempty([EEG.chanlocs(:).Z])
        EEG = pop_chanedit(EEG, 'load', {channel_locations_file});
        EEG.saved = 'no';
        fprintf(log_file,'%.2f - Loaded channel locations file from %s.\n',toc,channel_locations_file);
    end
    %EEG = pop_saveset(EEG,'savemode','resave');

    %%%%%%%%%%%%%%%%
    % Save options %
    %%%%%%%%%%%%%%%%
    do_saves=(~using_ALLEEG || (o.file_options.save_ALLEEG && ~isempty(EEG.filename)) || ~isempty(o.file_options.output_folder_name));
    if ~do_saves
        save_options = zeros(size(save_options));
    else
        EEG = pop_saveset(EEG, 'filename', [filename '.set'], ...
                          'filepath', filepath, 'savemode', 'onefile');
    end
    save_before_filter = save_options(1);
    save_before_interp = save_options(2);
    save_before_epoch = save_options(3);
    save_before_ica_rej = save_options(4);
    save_before_epoch_interp = save_options(5);

    if ~(o.filter_options.hpf_on || o.filter_options.lpf_on || ...
         o.filter_options.notch_on)
        % if none of these flags are set, we aren't doing any filtering
        do_filter = false;
    end
    
    if save_before_filter && do_filter
        save_step(EEG, 'pre_filt', 1, filepath)  
    end

    %%%%%%%%%%%%%
    % Filtering %
    %%%%%%%%%%%%%
    resample_frequency=o.filter_options.resample_freq;
    do_resample=o.filter_options.resample_on;
    % Downsampling is done later (shouldn't really be done at all).

    do_hipass=o.filter_options.hpf_on;
    do_lopass=o.filter_options.lpf_on;
    do_notch=o.filter_options.notch_on;

    if any(any(isnan(EEG.data)))
        fprintf('NaN in EEG data before filtering.\n');
    end

    if do_hipass
        w_h=o.filter_options.hpf_freq;
        t_h=o.filter_options.hpf_bandwidth;
        r_h=o.filter_options.hpf_ripple;
        a_h=o.filter_options.hpf_attenuation;

        [m, wtpass, wtstop] = pop_firpmord([w_h-(t_h) w_h+(t_h)], [0 1], [10^(-1*abs(a_h)/20) (10^(r_h/20)-1)/(10^(r_h/20)+1)], EEG.srate);
        if mod(m,2);m=m+1;end;
        EEG = pop_firpm(EEG, 'fcutoff', w_h, 'ftrans', t_h, 'ftype', 'highpass', 'wtpass', wtpass, 'wtstop', wtstop, 'forder', m);
        EEG.saved='no';
        fprintf(log_file,'%.2f - Highpass filter: %.3fHz, transition band: %.2f, order: %d.\n',toc,w_h,t_h,m);
    end

    if do_lopass
        w_l=o.filter_options.lpf_freq;
        t_l=o.filter_options.lpf_bandwidth;
        r_l=o.filter_options.lpf_ripple;
        a_l=o.filter_options.lpf_attenuation;

        [m, wtpass, wtstop] = pop_firpmord([w_l-(t_l) w_l+(t_l)], [1 0], [(10^(r_l/20)-1)/(10^(r_l/20)+1) 10^(-1*abs(a_l)/20)], EEG.srate);
        if mod(m,2);m=m+1;end;
        EEG = pop_firpm(EEG, 'fcutoff', w_l, 'ftrans', t_l, 'ftype', 'lowpass', 'wtpass', wtpass, 'wtstop', wtstop, 'forder', m);
        EEG.saved='no';
        fprintf(log_file,'%.2f - Lowpass filter: %.3fHz, transition band: %.2f, order: %d.\n',toc,w_l,t_l,m);
    end

    if do_notch
        for n=1:length(o.filter_options.notch_freq)
            w_n=[o.filter_options.notch_freq(n)-o.filter_options.notch_bandwidth1/2 o.filter_options.notch_freq(n)+o.filter_options.notch_bandwidth1/2];
            t_n=o.filter_options.notch_bandwidth2;
            r_n=o.filter_options.notch_ripple;
            a_n=o.filter_options.notch_attenuation;

            [m, wtpass, wtstop] = pop_firpmord([w_n(1)-(t_n) w_n(1)+(t_n) w_n(2)-(t_n) w_n(2)+(t_n)], [0 1 0], [10^(-1*abs(a_n)/20) (10^(r_n/20)-1)/(10^(r_n/20)+1) 10^(-1*abs(a_n)/20)], EEG.srate);
            if mod(m,2);m=m+1;end;
            EEG = pop_firpm(EEG, 'fcutoff', w_n, 'ftrans', t_n, 'ftype', 'bandstop', 'wtpass', wtpass, 'wtstop', wtstop, 'forder', m);
            EEG.saved='no';
            fprintf(log_file,'%.2f - Notch filter: %.3f to %.3fHz, transition band: %.2f, order: %d.\n',toc,w_n(1),w_n(2),t_n,m);
        end
    end

    if do_saves && do_filter
        % only save if we actually just changed something
        EEG = pop_saveset(EEG, 'savemode', 'resave');
    end

    if save_before_interp
        save_step(EEG, 'pre_interp', 2, filepath);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Channel interpolation options %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 1 Automatic interpolation of bad channels on or off (1 / 0)
    % 2 Radius for channel interpolation hypersphere (integer > 0)
    % 3 Automatic interpolation of channels per single epoch at end of process (1 / 0)
    % 4 Radius for epoch interpolation hypersphere (integer > 0)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    chans_to_interp = [];
    if o.channel_options.channel_rejection_on
        % find channels with poor connections
        o.channel_options.eog_chans = o.ica_options.EOG_channels;
        chans_to_interp = reject_channels(EEG, o.channel_options);
        
        if ~o.channel_options.interp_after_ica
            if ~isempty(chans_to_interp)
                fprintf('Interpolating channel(s)');
                fprintf(' %d', chans_to_interp);
                fprintf('.\n');
                EEG = h_eeg_interp_spl(EEG, chans_to_interp, ext_chans);
                EEG.saved = 'no';
                fprintf(log_file, '%.2f - Interpolated channels', toc);
                fprintf(log_file, ' %d', chans_to_interp);
                fprintf(log_file, '.\n');
            end
        end
    end

    if save_before_epoch
        save_step(EEG, 'pre_epoch', 3, filepath)
    end

    if do_resample
        % was developer note that resampling "creates problems",
        % with no other details. Use at your own risk
        old_name = EEG.setname;
        old_srate = EEG.srate;
        EEG = pop_resample(EEG, resample_frequency);
        EEG.setname = old_name;
        fprintf(log_file, '%.2f - Resampled from %dHz to %dHz.\n', ...
                toc, old_srate, resample_frequency);
    end

    %%%%%%%%%%%%%%%%%
    % Epoch options %
    %%%%%%%%%%%%%%%%%
    % 1 Epoching on or off (1 / 0)
    % 2 Markers to epoch from (array of integers or cell of strings)
    % 3 Epoch length (vector of 2 floats, 1 negative, 1 positive) - seconds
    % 4 Baseline length for mean subtraction (vector of 2 integers) (0 => baseline subtraction off) - milliseconds
    % 5 Auto epoch rejection on or off (1 / 0)
    % 6 Radius for epoch rejection hypersphere (integer > 0)
    %%%%%%%%%%%%%%%%%
    markers = o.epoch_options.epoch_markers;
    epoch_length = o.epoch_options.epoch_limits;
    baseline_time = o.epoch_options.baseline_sub * 1000;
    do_epoch_rejection = o.epoch_options.epoch_rejection_on;
    do_epoching = ((~isempty(markers) && o.epoch_options.markered_epoch) || o.epoch_options.unmarkered_epoch) && any(o.epoch_options.epoch_limits) && length(o.epoch_options.epoch_limits)==2;

    %%%%%%%%%%%%%%
    % Epoch data %
    %%%%%%%%%%%%%%
    if do_epoching
        % segment continous data into epochs
        oldname = EEG.setname;
        if ~o.epoch_options.unmarkered_epoch
            EEGt = h_epoch(EEG,markers,epoch_length);
            EEG.setname = oldname;
            EEG.saved='no';
            if isnumeric(markers)
                fprintf(log_file,'%.2f - Epoched data on markers',toc);
                fprintf(log_file,' %d',markers);
                fprintf(log_file,'.\n');
            else
                fprintf(log_file,'%.2f - Epoched data on markers',toc);
                fprintf(log_file,' %s',markers{:});
                fprintf(log_file,'.\n');
            end
            if size(EEG.data,3)==0
                fprintf(log_file,'Epoch length too short, no epochs were generated.\n');
            else
                EEG=EEGt;
                clear EEGt;
            end
        else
            EEG = eeg_regepochs(EEG,o.epoch_options.unmarkered_epoch_interval,epoch_length,NaN);
            EEG.setname = oldname;
            EEG.saved='no';
            fprintf(log_file, ...
                    '%.2f - Epoched data every %.2f seconds.\n', ...
                    toc, o.epoch_options.unmarkered_epoch_interval);
        end
    end
    
    if size(EEG.data, 3) > 1
        % remove epoch baselines after epoching
        if any(baseline_time)
            if ~epoch_overlap
                EEG = pop_rmbase(EEG, baseline_time);
                % rereference just to print baseline variance, as
                % otherwise the initial BL variance is with a single
                % reference, and the final in average reference
                EEGtemp = h_pop_reref(EEG, [], 'exclude', ext_chans, ...
                                      'refstate', ref_chan);
            else
                % do this just for calculating baseline variance;
                % do not change the dataset for subsequent processing
                EEGtemp = pop_rmbase(EEG, baseline_time);
                EEGtemp = h_pop_reref(EEGtemp, [], 'exclude', ext_chans, ...
                                      'refstate', ref_chan);
            end
        end
        
        fprintf(log_file, 'Initial baseline variance: %.2f.\n', ...
                baseline_var(EEGtemp));
        clear EEGtemp;
    end

    %if (do_saves), EEG = pop_saveset(EEG,'savemode','resave'); end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Epoch rejection section %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    if do_epoch_rejection && size(EEG.data, 3) > 1
        % get channels to use
        if o.channel_options.interp_after_ica
            chans_for_rej = setdiff(eeg_chans, chans_to_interp);
        else
            chans_for_rej = eeg_chans;
        end
        
        % get epoch stats
        if epoch_overlap
            % stats expect baseline correction here, but need to
            % have uncorrected data for ICA
            EEGtemp = pop_rmbase(EEG, baseline_time);
            list_properties = epoch_properties(EEGtemp, chans_for_rej);
            clear EEGtemp
        else
            list_properties = epoch_properties(EEG, chans_for_rej);
        end
        
        lengths = min_z(list_properties, o.epoch_options.rejection_options);
        EEG = pop_rejepoch(EEG, find(lengths), 0);
        fprintf(log_file, '%.2f - Rejected %d epochs', toc, nnz(lengths));
        fprintf(log_file, ' %d', find(lengths));
        fprintf(log_file, '.\n');
        EEG.saved = 'no';
    end

    if do_saves
        EEG = pop_saveset(EEG, 'savemode', 'resave');
    end

    %%%%%%%%%%%%%%%
    % ICA options %
    %%%%%%%%%%%%%%%
    % 1 ICA on or off (1 / 0)
    % 2 Auto component rejection on or off (1 / 0)
    % 3 Radius for component rejection hypersphere (integer > 0)
    % 4 EOG channels (vector of integers)
    %%%%%%%%%%%%%%%
    do_ica = o.ica_options.run_ica;
    k_value = o.ica_options.k_value;
    do_component_rejection = o.ica_options.component_rejection_on;
    EOG_chans = o.ica_options.EOG_channels;
    EMG_chans = o.ica_options.EMG_channels;
    ica_chans = o.ica_options.ica_channels;

    %%%%%%%%%%
    % Do ICA %
    %%%%%%%%%%
    if do_ica && (~o.ica_options.keep_ICA || isempty(EEG.icaweights))
        if epoch_overlap
            % remove overlap before ICA
            EEG = eeg_remove_epoch_overlap(EEG);
        end
      
        % max number of components that will be estimable given the
        % number of samples we have
        n_max_recommend = floor(sqrt(size(EEG.data(:,:), 2) / k_value));

        if o.channel_options.interp_after_ica
            % exclude bad channels, which will be interpolated later
            ica_chans = intersect(setdiff(ica_chans, chans_to_interp), ...
                                  union(eeg_chans, ext_chans));
            
            % determine the number of components to reduce to before
            % ICA. Don't go over: (1) the number of estimable
            % components, (2) the number of included channels, (3)
            % the user-specified maximum
            num_pca = min([n_max_recommend length(ica_chans) n_max_pca]);
            EEG = pop_runica(EEG, 'dataset', 1, ...
                'chanind', setdiff(ica_chans, chans_to_interp), ...
                'icatype', 'binica', ...
                'options', {'extended', 1, 'pca', num_pca});
        else
            % bad channels already interpolated
            ica_chans = intersect(ica_chans, union(eeg_chans, ext_chans));
            num_pca = min([n_max_recommend length(ica_chans) n_max_pca]);
            EEG = pop_runica(EEG, 'dataset', 1, 'chanind', ica_chans, ...
                             'options', {'extended', 1, 'pca', num_pca});
        end
        EEG.saved = 'no';
        if epoch_overlap
            % convert back to overlapping segmented data
            EEG = eeg_epoch_overlap(EEG);
        end
        
        fprintf(log_file, '%.2f - Ran ICA.\n', toc);
    end

    if do_saves
        EEG = pop_saveset(EEG, 'savemode', 'resave');
    end

    if save_before_ica_rej
        save_step(EEG, 'pre_comp_rej', 4, filepath)
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Component rejection section %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if do_component_rejection && ~isempty(EEG.icaweights)
        % rejecting components
        EEG = eeg_checkset(EEG);
        original_name = EEG.setname;
        if do_lopass
            % check for white noise in the filtered band
            filt_band = [w_l-(t_l/2) w_l+(t_l/2)];
        elseif ~isempty(o.ica_options.lopass_freq) && ...
              o.ica_options.lopass_freq ~= 0
            % get frequencies around a specified point
            filt_band = [o.ica_options.lopass_freq - 5 ...
                         o.ica_options.lopass_freq + 5];
        else
            filt_band = [];
        end
        
        % component stats
        [list_properties, prop_type] = component_properties(EEG, ...
            EOG_chans, filt_band, EMG_chans);

        if isempty(filt_band)
          o.ica_options.rejection_options.measure(2) = 0;
        end

        lengths = min_z(list_properties, ...
                        o.ica_options.rejection_options, prop_type);
        bad_comps = find(lengths);

        % plot components, indicating variance and which are rejected
        if o.ica_options.IC_images
            plot_ica_rej(EEG, filepath, bad_comps);
        end

        % reject components
        if any(lengths)
            fprintf('Rejecting components');
            fprintf(' %d', find(lengths));
            fprintf('.\n');
            EEG = pop_subcomp(EEG, find(lengths), 0);
            fprintf(log_file, '%.2f - Rejected %d components', ...
                    toc, nnz(lengths));
            fprintf(log_file, ' %d', find(lengths));
            fprintf(log_file, '.\n');
        else
            fprintf('Rejected no components.\n');
            fprintf(log_file, '%.2f - Rejected no components.\n',toc);
        end
        EEG.setname = original_name;
        EEG.saved = 'no';
    elseif ~isempty(EEG.icawinv) && o.ica_options.IC_images
        % no component rejection; just plot components
        plot_ica_rej(EEG, filepath, []);
    end

    if do_saves
        EEG = pop_saveset(EEG, 'savemode', 'resave');
    end

    if save_before_epoch_interp
        save_step(EEG, 'pre_epoch_interp', 5, filepath)
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Post-ICA Channel Interpolation %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if o.channel_options.interp_after_ica
        if ~isempty(chans_to_interp)
            fprintf('Interpolating channel(s)');
            fprintf(' %d', chans_to_interp);
            fprintf('.\n');
            EEG = h_eeg_interp_spl(EEG, chans_to_interp, ext_chans);
            EEG.saved = 'no';
            fprintf(log_file, '%.2f - Interpolated channels',toc);
            fprintf(log_file, ' %d', chans_to_interp);
            fprintf(log_file, '.\n');
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Epoch interpolation section %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    do_epoch_interp=o.epoch_interp_options.epoch_interpolation_on;
    if do_epoch_interp && length(size(EEG.data)) > 2
        if epoch_overlap
            % about to do epoch-based rejection, so finally run
            % baseline correction here
            EEG = pop_rmbase(EEG, baseline_time);
        end
      
        % additional check to remove bad channel-epochs
        amp_diffs = epoch_amp_diff(EEG, eeg_chans);
        
        status = '';
        lengths_ep=cell(1,size(EEG.data,3));
        excluded = false(1, size(EEG.data, 3));
        for v=1:size(EEG.data,3)
            % standard stats for identifying bad channel-epochs
            % exclude channels with very high amplitude changes
            high_amp_diff = amp_diffs(:,v) > amp_diff_thresh;
            good_chans = eeg_chans(~high_amp_diff);
            list_properties = single_epoch_channel_properties(EEG,v,good_chans);
            rejected = logical(min_z(list_properties,o.epoch_interp_options.rejection_options));
            
            % get full list of excluded channels
            lengths_ep{v} = sort([eeg_chans(high_amp_diff) good_chans(rejected)]);
            
            status = [status sprintf('%d: ',v) sprintf('%d ',lengths_ep{v}) sprintf('\n')];

            if length(lengths_ep{v}) > bad_epoch_thresh
              % if there were a large number of bad channels for
              % this epoch, will throw it out completely
              excluded(v) = true;
              
              % no need to interpolate
              lengths_ep{v} = [];
            end
        end
        EEG=h_epoch_interp_spl(EEG,lengths_ep,ext_chans);
        EEG.saved='no';
        epoch_interps_log_file=fopen([filepath filesep filename '_epoch_interpolations.txt'],'w');
        fprintf(epoch_interps_log_file,'%s',status);
        fclose(epoch_interps_log_file);
        fprintf(log_file,'%.2f - Did per-epoch interpolation cleanup.\n',toc);
        fprintf(log_file,['See ' filename(1:end-4) '_epoch_interpolations.txt for details.\n']);
    end

    if save_before_epoch_interp
        save_step(EEG, 'pre_average_ref', 6, filepath)
    end
    
    %%%%%%%%%%%%%%%%%%%%%
    % Average reference %
    %%%%%%%%%%%%%%%%%%%%%
    % convert to average reference AFTER rejecting epoch-channels,
    % so that bad channels in a given epoch do not contaminate the
    % average reference and get spread to clean channels
    if do_reref && ~o.ica_options.keep_ICA
        % this is after ICA and all interpolation, so include all
        % non-external channels
        EEG = h_pop_reref(EEG, [], 'exclude', ext_chans, 'refstate', ...
                          ref_chan);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Epochs in channels/epochs - Second pass with average reference %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if do_epoch_interp && length(size(EEG.data)) > 2
        status = '';
        lengths_ep=cell(1,size(EEG.data,3));
        % lower the thresholds for this final pass
        %o.epoch_interp_options.rejection_options.z = ...
        %    o.epoch_interp_options.rejection_options.z / 2;
        
        for v=1:size(EEG.data,3)
            list_properties = single_epoch_channel_properties(EEG,v,eeg_chans);
            rejected = logical(min_z(list_properties,o.epoch_interp_options.rejection_options));
            lengths_ep{v} = eeg_chans(rejected);
            
            status = [status sprintf('%d: ',v) sprintf('%d ',lengths_ep{v}) sprintf('\n')];

            if length(lengths_ep{v}) > bad_epoch_thresh
              % if there were a large number of bad channels for
              % this epoch, will throw it out completely
              excluded(v) = true;
              
              % no need to interpolate
              lengths_ep{v} = [];
            end
        end
        EEG = h_epoch_interp_spl(EEG, lengths_ep, ext_chans);
        EEG.saved = 'no';

        log_filepath = fullfile(filepath, sprintf('%s_%s', ...
             filename, 'epoch_interpolations_average_ref.txt'));
        epoch_interps_log_file = fopen(log_filepath, 'w');
        fprintf(epoch_interps_log_file, '%s', status);
        fclose(epoch_interps_log_file);
        
        fprintf(log_file, ...
                '%.2f - Did per-epoch interpolation cleanup, second pass.\n', ...
                toc);
        [~, epoch_interps_log_name] = fileparts(log_filepath);
        fprintf(log_file, ...
                sprintf('See %s for details.\n', epoch_interps_log_name));
    end
    
    if save_before_epoch_interp
        save_step(EEG, 'pre_final_epoch_rej', 7, filepath)
    end
    
    % remove epochs with too many bad electrodes
    EEG = pop_select(EEG, 'notrial', find(excluded));
    EEG.saved = 'no';
    
    % reference to a single channel for the output if requested
    if ~isempty(o.channel_options.op_ref_chan)
        EEG = h_pop_reref(EEG, o.channel_options.op_ref_chan, 'exclude',ext_chans, 'refstate', [], 'keepref', 'on');
    end
    if do_saves
        EEG = pop_saveset(EEG, 'savemode', 'resave');
    end

    if using_ALLEEG
        fprintf('Done with ALLEEG(%d) - %s.\nTook %d seconds.\n',o.file_options.current_file_num,EEG.setname,toc);
    else
        fprintf('Done with file %s.\nTook %d seconds.\n', ...
                fullfile(EEG.filepath, EEG.filename), toc);
    end

    % report stats on final results
    fprintf(log_file,'%.2f - Finished.\n',toc);
    if size(EEG.data, 3) > 1
        fprintf(log_file, 'Final baseline variance: %.2f.\n', ...
                baseline_var(EEG));
    end
    fclose(log_file);

    % modify ALLEEG in the base workspace
    if using_ALLEEG
        assignin('base', 'FASTER_TMP_EEG', EEG);
        if o.file_options.overwrite_ALLEEG
            evalin('base',sprintf('ALLEEG(%d)=FASTER_TMP_EEG; clear FASTER_TMP_EEG',o.file_options.current_file_num));
        else
            evalin('base','[ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, FASTER_TMP_EEG);clear FASTER_TMP_EEG;');
        end
    end
catch
    % deal with errors encountered at any point
    m = lasterror;
    EEG_state{1} = evalc('disp(EEG)');
    try
        if ~isempty(fopen(log_file))
            frewind(log_file);
            EEG_state{2} = fscanf(log_file, '%c', inf);
            
            try
                fclose(log_file);
            catch
            end
        end
    catch
    end
    EEG_state{3} = option_wrapper;
    EEG_state{4} = builtin('version');
    if exist('eeg_getversion', 'file')
        EEG_state{5} = eeg_getversion;
    else
        EEG_state{5} = which('eeglab');
    end
    
    assignin('caller', 'EEG_state', EEG_state);
    rethrow(m);
end


function [EEG, filepath, filename] = prep_files(o, log_file)

    % unpack options
    prefix = o.file_options.file_prefix;
    fullfilename = o.file_options.current_file;
    [~, filename, extension] = fileparts(fullfilename);
    using_ALLEEG = o.file_options.using_ALLEEG;
    filepath = o.file_options.oplist{o.file_options.current_file_num};
    
    % create the intermediate dir to save steps along the way
    int_dir = fullfile(filepath, 'Intermediate');
    if ~exist(int_dir, 'dir')
        mkdir(int_dir)
    end
    
    % Note: import all channels and then remove the unnecessary ones, as
    % otherwise the event channel gets removed and we have no event data.
    if strcmpi(extension, '.bdf') && ~using_ALLEEG
        % import a .bdf file
        fprintf('Importing %s.\n', fullfilename);
        EEG = pop_biosig(fullfilename);
        EEG.setname = filename;
        
        % save to a dataset file
        filename = [o.file_options.file_prefix filename];
        EEG = pop_saveset(EEG, 'filename', [filename '.set'], ...
                          'filepath', filepath, 'savemode', 'onefile');
        fprintf(log_file, '%.2f - Imported and converted file %s.\n', ...
                toc, fullfilename);
    elseif strcmpi(extension, '.set') && ~using_ALLEEG
        % load an existing dataset
        fprintf('Loading %s.\n', fullfilename);
        EEG = pop_loadset('filename', [filename '.set'], ...
                          'filepath', filepath);
        fprintf(log_file, '%.2f - Loaded file %s.\n' , toc, fullfilename);
        
        if isempty(o.file_options.output_folder_name)
            % save to the intermediate directory
            pop_saveset(EEG, 'filename', ['Original_' filename '.set'], ...
                        'filepath', int_dir);
            
            % delete the original files
            delete(fullfilename);
            if exist([fullfilename(1:end-4) '.fdt'],'file')
                delete([fullfilename(1:end-4) '.fdt']);
            end
            if exist([fullfilename(1:end-4) '.dat'],'file')
                delete([fullfilename(1:end-4) '.dat']);
            end
        end
        filename = [o.file_options.file_prefix filename];
        EEG.filename = [filename '.set'];
    elseif using_ALLEEG
        % use one of the datasets in memory
        EEG = evalin('base', sprintf('ALLEEG(%d);', ...
            o.file_options.plist{o.file_options.current_file_num}));

        if ~isempty(EEG.filename)
            filename = sprintf('%s%s.set', prefix, EEG.filename);
        elseif ~isempty(EEG.setname)
            filename = sprintf('%sALLEEG(%d)_%s.set', prefix, ...
                               o.file_options.current_file_num, EEG.setname);
        else
            filename = sprintf('%sALLEEG(%d).set', prefix, ...
                               o.file_options.current_file_num);
        end
        EEG.filepath = filepath;
        EEG.filename = filename;
    else
        EEG = [];
        fprintf('Unknown file format.\n');
        fprintf(log_file,'%.2f - Unknown file format. Cannot process.\n',toc);
        return
    end
    
    % check the imported data for consistency
    EEG = eeg_checkset(EEG);
  
function save_step(EEG, step_name, step_number, filepath)
    
    EEG.setname = sprintf('%s_%s', step_name, EEG.setname);
    filename = sprintf('%d_%s_%s', step_number, step_name, EEG.filename);
    pop_saveset(EEG, 'filename', filename, ...
                'filepath', fullfile(filepath, 'Intermediate'), ...
                'savemode', 'onefile');
    
function base_var = baseline_var(EEG)
    
    % assuming that the early bound is negative; baseline is everything
    % from that to t=0 (generally stimulus onset)
    baseline_ind = 1:round(EEG.srate * -EEG.xmin);
      
    base_var = median(var(mean(EEG.data(:,baseline_ind,:), 3), [], 2));

function plot_ica_rej(EEG, filepath, bad_comps)
      
    p = 1;
    
    % get component topography and variance accounted for
    activations = eeg_getica(EEG);
    perc_vars = var(activations(:,:), [], 2);
    perc_vars = 100 * perc_vars ./ sum(perc_vars);
    for u = 1:size(EEG.icawinv, 2)
        if ~mod(u - 1, 16)
            if u ~= 1
                % have a full array of plots; print
                fig_file = fullfile(filepath, 'Intermediate', ...
                                    sprintf('Components_%d.png', p));
                saveas(h, fig_file);
                p = p + 1;
                close(h);
            end
            h = figure;
        end

        % plot topography of this component
        subplot(4, 4, 1 + mod(u - 1, 16));
        topoplot(EEG.icawinv(:,u), EEG.chanlocs(EEG.icachansind));
        title(sprintf('Component %d\n%.1f%% variance', u, perc_vars(u)));

        if any(bad_comps == u)
            % highlight any bad components
            c = get(h, 'Children');
            c2 = get(c(1), 'Children');
            set(c2(5), 'FaceColor', [0.6 0 0]);
            x = get(c2(5), 'XData');
            x(1:end / 2) = 1.5 * (x(1:end / 2));
            set(c2(5), 'XData', x);
            y = get(c2(5), 'YData');
            y(1:end / 2) = 1.5 * (y(1:end / 2));
            set(c2(5), 'YData', y);
        end
    end

    % print the final panel
    fig_file = fullfile(filepath, 'Intermediate', ...
                        sprintf('Components_%d.png', p));
    saveas(h, fig_file);
    if ~isempty(h)
        close(h);
    end     
    
    