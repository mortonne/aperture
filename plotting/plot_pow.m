function h = plot_pow(values, dim, limits)
%h = plot_pow_sig(values, p_range)

if ~exist('limits', 'var')
  limits = [];
end

clf reset

x = getStructField(dim.time, 'avg');
if size(values,2)==1
	xlim = [dim.time(1).MSvals(1) dim.time(end).MSvals(end)];
	x = [mean([xlim(1) x]) mean([xlim(2) x])];
	values = repmat(values,1,2);
end
y = log10(getStructField(dim.freq, 'avg'));

set(gca, 'XLim', xlim)

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
