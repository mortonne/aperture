function h = plot_pow(values, dim, limits)
%h = plot_pow_sig(values, p_range)

if ~exist('limits', 'var')
  limits = [];
end

clf reset

x = getStructField(dim.time, 'avg');
y = log10(getStructField(dim.freq, 'avg'));

if ~isempty(limits)
  h = imagesc(x, y, values, limits);
else
  h = imagesc(x, y, values);
end

axis xy
set(gca, 'YTick', log10([2 4 8 16 32 64 128]))
set(gca, 'YTickLabel', [2 4 8 16 32 64 128])
set(gca, 'LineWidth', 2)
xlabel('Time (ms)')
ylabel('Frequency (Hz)')

c = colorbar;
set(c, 'LineWidth', 2)
publishFig
