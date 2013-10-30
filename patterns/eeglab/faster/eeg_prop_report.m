function pdf_file = eeg_prop_report(EEG, res_dir, report_name)
%EEG_PROP_REPORT   Create report on properties of components.
%
%  pdf_file = eeg_prop_report(EEG, res_dir, report_name)

if nargin < 3
  report_name = 'prop_report';
end

n_sample = 10;

fig_dir = fullfile(res_dir, 'figs');
if ~exist(fig_dir, 'dir')
  mkdir(fig_dir)
end

% calculate properties for epoch sorting
if ~isfield(EEG, 'icaact') || isempty(EEG.icaact)
  EEG.data = eeg_getica(EEG);
else
  EEG.data = EEG.icaact;
  EEG.icaact = [];
end
epoch_comp_var = permute(var(EEG.data, [], 2), [3 1 2]);
ssfast = sum(diff(EEG.data, [], 2).^2, 2);
sstot = sum((EEG.data - ...
             repmat(mean(EEG.data, 2), [1 EEG.pnts 1])).^2, 2);
epoch_comp_fast = permute(ssfast ./ sstot, [3 1 2]);

f = figure;
n_comp = size(EEG.icawinv, 2);
files = cell(n_comp, 5);
labels = cellfun(@(x) sprintf('IC%d', x), num2cell(1:n_comp), ...
                 'UniformOutput', false);
for i = 1:n_comp
  %% component topography
  clf
  topoplot(EEG.icawinv(:,i), EEG.chanlocs, 'chaninfo', EEG.chaninfo, ...
           'shading', 'interp', 'numcontour', 3);
  axis square
  files{i,1} = fullfile(fig_dir, ['topo_' labels{i}]);
  print(gcf, '-djpeg', files{i,1});
  
  %% ERP image
  x = EEG.data(i,:,:);
  clf
  lim = max(abs([prctile(x(:), 10) prctile(x(:), 90)]));
  erpimage(x, repmat(10000, 1, EEG.trials), EEG.times * 1000, ...
           '', 3, 1, 'caxis', [-lim lim], 'cbar', 'erp');
  files{i,2} = fullfile(fig_dir, ['erpimage_' labels{i}]);
  print(gcf, '-djpeg', files{i,2});
  
  %% spectrum
  clf
  [spectra, freqs] = spectopo(x, EEG.pnts, EEG.srate, ...
                              'freqrange', [2 65], ...
                              'mapnorm', EEG.icawinv(:,i));
  files{i,3} = fullfile(fig_dir, ['spect_' labels{i}]);
  print(gcf, '-djpeg', files{i,3});
  
  %% sample epochs based on variance
  clf
  [~, ind] = sort(epoch_comp_var(:,i), 1, 'descend');
  for j = 1:n_sample
    subplot(n_sample, 1, j);
    plot(EEG.times, x(:,:,ind(j)), '-k', 'LineWidth', 2);
    if j < n_sample
      set(gca, 'XTickLabel', {}, 'XTick', [])
    end
    set(gca, 'XLim', [EEG.times(1) EEG.times(end)]);
  end
  xlabel('Time (ms)')
  files{i,4} = fullfile(fig_dir, ['trace_var_' labels{i}]);
  print(gcf, '-djpeg', files{i,4});

  clf
  %% sample epochs with fast changes
  %m = median(diff(permute(x, [3 2 1]), 1, 2), 2);
  %[~, ind] = sort(m, 1, 'descend');
  [~, ind] = sort(epoch_comp_fast(:,i), 1, 'descend');
  for j = 1:n_sample
    subplot(n_sample, 1, j);
    plot(EEG.times, x(:,:,ind(j)), '-k', 'LineWidth', 2);
    if j < n_sample
      set(gca, 'XTickLabel', {}, 'XTick', [])
    end
    set(gca, 'XLim', [EEG.times(1) EEG.times(end)]);
  end
  xlabel('Time (ms)')
  files{i,5} = fullfile(fig_dir, ['trace_fast_' labels{i}]);
  print(gcf, '-djpeg', files{i,5});
end

%% write latex code
header = {'Component' 'Topo' 'ERP Image' ...
          'Spectrum' 'Traces (var)' 'Traces (fast)'};
table = create_report(files, labels, ...
                      'max_label_length', length(header{1}));
report_file = fullfile(res_dir, report_name);
longtable(report_file, table, 'orientation', 'portrait', ...
          'header', header);

% compilation fails for some reason when called from within matlab
pdf_file = pdflatex(report_file, 'pdflatex');
%pdf_file = '';

close(f);

