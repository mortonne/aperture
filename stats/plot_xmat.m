function h = plot_xmat(X)
%PLOT_XMAT   Plot an image of a design matrix.
%
%  h = plot_xmat(X)

clf
[n_obs, n_reg] = size(X);

colormap(gray);
h = imagesc(X);
set(gca, 'XTick', 1:n_reg)

l = line(repmat((1:n_reg-1) + 0.5, 2, 1), repmat([0; n_obs], 1, n_reg-1));
set(l, 'Color', 'y');
axis off

