function pdf_file = eeg_prop_report(EEG, res_dir, report_name, ica)
%EEG_PROP_REPORT   Create report on properties of components.
%
%  pdf_file = eeg_prop_report(EEG, res_dir, report_name)

if nargin < 4
  ica = true;
  if nargin < 3
    report_name = 'prop_report';
  end
end

n_sample = 10;

res_dir = check_dir(res_dir);
fig_dir = fullfile(res_dir, ['figs_' report_name]);
if ~exist(fig_dir, 'dir')
  mkdir(fig_dir)
end

% calculate properties for epoch sorting
if ica
  if ~isfield(EEG, 'icaact') || isempty(EEG.icaact)
    EEG.data = eeg_getica(EEG);
  else
    EEG.data = EEG.icaact;
    EEG.icaact = [];
  end
  n_comp = size(EEG.icawinv, 2);
  labels = cellfun(@(x) sprintf('IC%d', x), num2cell(1:n_comp), ...
                 'UniformOutput', false);
else
  n_comp = EEG.nbchan;
  labels = cellfun(@(x) sprintf('%d', x), num2cell(1:n_comp), ...
                 'UniformOutput', false);
end
epoch_comp_var = permute(var(EEG.data, [], 2), [3 1 2]);
ssfast = sum(diff(EEG.data, [], 2).^2, 2);
sstot = sum((EEG.data - ...
             repmat(mean(EEG.data, 2), [1 EEG.pnts 1])).^2, 2);
epoch_comp_fast = permute(ssfast ./ sstot, [3 1 2]);

if ica && isfield(EEG, 'chanlocs') && ~isempty(EEG.chanlocs)
  do_topo = true;
  n_figs = 5;
else
  do_topo = false;
  n_figs = 4;
end
  
files = cell(n_comp, n_figs);

for i = 1:n_comp
  f = figure;
  n = 1;
  
  %% component topography
  if do_topo
    clf reset
    topoplot(EEG.icawinv(:,i), EEG.chanlocs, 'chaninfo', EEG.chaninfo, ...
             'shading', 'interp', 'numcontour', 3);
    axis square
    files{i,n} = fullfile(fig_dir, ['topo_' labels{i} '.jpg']);
    print(gcf, '-djpeg', files{i,n});
  end
  n = n + 1;
  
  %% ERP image
  x = EEG.data(i,:,:);
  clf reset
  h = plot_erp_image(squeeze(x)', EEG.times);
  
  files{i,n} = fullfile(fig_dir, ['erpimage_' labels{i} '.jpg']);
  print(gcf, '-djpeg95', files{i,n});
  n = n + 1;

  %% spectrum
  clf reset
  if ica
    [spectra, freqs] = spectopo(x, EEG.pnts, EEG.srate, ...
                                'freqrange', [2 55], ...
                                'mapnorm', EEG.icawinv(:,i));
  else
    [spectra, freqs] = spectopo(x, EEG.pnts, EEG.srate, ...
                                'freqrange', [2 55]);
  end
  files{i,n} = fullfile(fig_dir, ['spect_' labels{i} '.jpg']);
  print(gcf, '-djpeg', files{i,n});
  n = n + 1;
  
  %% sample epochs based on variance
  clf reset
  [~, ind] = sort(epoch_comp_var(:,i), 1, 'descend');
  for j = 1:n_sample
    subplot(n_sample, 1, j);
    plot(EEG.times, x(:,:,ind(j)), '-k', 'LineWidth', 1);
    if j < n_sample
      set(gca, 'XTickLabel', {}, 'XTick', [])
    end
    set(gca, 'XLim', [EEG.times(1) EEG.times(end)]);
  end
  xlabel('Time (ms)')
  files{i,n} = fullfile(fig_dir, ['trace_var_' labels{i} '.jpg']);
  print(gcf, '-djpeg', files{i,n});
  n = n + 1;

  clf reset
  %% sample epochs with fast changes
  %m = median(diff(permute(x, [3 2 1]), 1, 2), 2);
  %[~, ind] = sort(m, 1, 'descend');
  [~, ind] = sort(epoch_comp_fast(:,i), 1, 'descend');
  for j = 1:n_sample
    subplot(n_sample, 1, j);
    plot(EEG.times, x(:,:,ind(j)), '-k', 'LineWidth', 1);
    if j < n_sample
      set(gca, 'XTickLabel', {}, 'XTick', [])
    end
    set(gca, 'XLim', [EEG.times(1) EEG.times(end)]);
  end
  xlabel('Time (ms)')
  files{i,5} = fullfile(fig_dir, ['trace_fast_' labels{i} '.jpg']);
  print(gcf, '-djpeg', files{i,n});
  n = n + 1;
  
  close(f);
end

%% write latex code
if ica
  header = {'Component' 'Topo' 'ERP Image' ...
            'Spectrum' 'Traces (var)' 'Traces (fast)'};
else
  header = {'Channel' 'Topo' 'ERP Image' ...
            'Spectrum' 'Traces (var)' 'Traces (fast)'};
end
table = create_report(files, labels, ...
                      'max_label_length', length(header{1}));
report_file = fullfile(res_dir, report_name);
longtable(report_file, table, 'orientation', 'portrait', ...
          'header', header);

% compilation fails for some reason when called from within matlab
pdf_file = pdflatex(report_file, 'pdflatex');
%pdf_file = '';

if exist(pdf_file, 'file')
  % delete the source files
  for i = 1:numel(files)
    delete(files{i});
  end
  try
    rmdir(fig_dir);
  catch
  end
  
  delete(report_file);
  delete([report_file '.aux']);
  delete([report_file '.log']);
end

