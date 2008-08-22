function [pat,status] = pc_stats(pat, plotit)

if ~exist('plotit','var')
  plotit = 1;
end
if ~exist('params','var')
  params = struct();
end

params = structDefaults(params, 'loadSingles', 1);
status = 1;

pattern = loadPat(pat, params);

% flatten all dimensions after events into one vector
fprintf('vectorizing...')
patsize = size(pattern);
if length(patsize)>2
  pattern = reshape(pattern, [patsize(1) prod(patsize(2:end))]);
end

% deal with any nans in the pattern (variables may be thrown out)
pattern = remove_nans(pattern);

% get principal components
fprintf('getting principal components...')
[coeff,pattern,l,t2] = princomp(pattern,'econ');

p_explained = l/sum(l);

%coeff = coeff(:,1)';
%coeff = reshape(coeff, [patsize(2:end)]);

if plotit
  %{
  for c=1:size(coeff,1)
    figure(c)
    plot_pow(squeeze(coeff(c,:,:)), pat.dim);
    title(pat.dim.chan(c).label)
  end
  %}

  plot(cumsum(p_explained));
  xlabel('Principal Component')
  ylabel('Cumulative Variance Explained')
  title(pat.source)
  set(gca, 'YLim', [0 1])
  drawnow
end

figure(gcf+1)
