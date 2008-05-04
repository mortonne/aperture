function h = plot_pow_sig(values, dim, p_range)
%h = plot_pow_sig(values, p_range)

x = getStructField(dim.time, 'avg');
y = log10(getStructField(dim.freq, 'avg'));

totLen = 128;
two_way = 1;
signed = 1;

if two_way
	p_range = p_range/2;
	
	values(values>0) = (1-values(values>0))/2+.5;
	values(values<0) = ((-1-values(values<0))+1)/2;
  colors{1,1} = [0.0 0.0 1.0];
  colors{1,2} = [0.8 0.8 1.0];
  colors{2,1} = [1.0 1.0 1.0];
  colors{2,2} = [1.0 1.0 1.0];
  colors{3,1} = [1.0 0.8 0.8];
  colors{3,2} = [1.0 0.0 0.0];
  
  vals(1,1) = p_range(2);
  vals(1,2) = p_range(1);
  vals(2,1) = p_range(1);
  vals(2,2) = 1-p_range(1);
  vals(3,1) = 1-p_range(1);
  vals(3,2) = 1-p_range(2);
elseif signed

	colors{1,1} = [1.0 1.0 1.0];
	colors{1,2} = [1.0 1.0 1.0];
	colors{2,1} = [1.0 0.8 0.8];
	colors{2,2} = [1.0 0.0 0.0];
	colors{3,1} = [1.0 0.0 0.0];
	colors{3,2} = [1.0 0.0 0.0];
	colors{4,1} = [0.0 0.0 1.0];
	colors{4,2} = [0.0 0.0 1.0];
	colors{5,1} = [0.0 0.0 1.0];
	colors{5,2} = [0.8 0.8 1.0];
	colors{6,1} = [1.0 1.0 1.0];
	colors{6,2} = [1.0 1.0 1.0];
	
	vals(1,1) = 1;
	vals(1,2) = p_range(1);
	vals(2,1) = p_range(1);
	vals(2,2) = p_range(2);
	vals(3,1) = p_range(2);
	vals(3,2) = 0;
	vals(4,1) = 0;
	vals(4,2) = -p_range(2);
	vals(5,1) = -p_range(2);
	vals(5,2) = -p_range(1);
	vals(6,1) = -p_range(1);
	vals(6,2) = -1;
	keyboard
else

  colors{1,1} = [0.0 0.0 1.0];
  colors{1,2} = [0.8 0.8 1.0];
  colors{2,1} = [1.0 1.0 1.0];
  colors{2,2} = [1.0 1.0 1.0];
  
  vals(1,1) = p_range(2);
  vals(1,2) = p_range(1);
  vals(2,1) = p_range(1);
  vals(2,2) = 1-p_range(1);
end

oldvals = vals;
oldvalues = values;
oldlimits = [oldvals(1) oldvals(end)];

vals = norminv(vals);
values = norminv(values);
maplimits = [vals(1) vals(end)];
values(values<maplimits(1)) = maplimits(1);
values(values>maplimits(2)) = maplimits(2);
    
if exist('colors', 'var')
  map = [];
  for i=1:size(colors,1)
    colLen = fix(abs(diff(vals(i,:))/diff(maplimits))*(totLen+1));
    map = [map; makecolormap(colors{i,1}, colors{i,2}, colLen)];
  end
end

h = imagesc(x, y, values, maplimits);
axis xy
set(gca, 'YTick', log10([2 4 8 16 32 64 128]))
set(gca, 'YTickLabel', [2 4 8 16 32 64 128])
xlabel('Time (ms)')
ylabel('Frequency (Hz)')
set(gca, 'LineWidth', 2)

colormap(map)
c = colorbar;
set(c, 'YTick', [norminv(p_range(2)) norminv(p_range(1))])
set(c, 'YTickLabel', [.005 .05])
set(c, 'LineWidth', 2)
%publishFig
