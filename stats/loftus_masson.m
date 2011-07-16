function err = loftus_masson(dat)
%LOFTUS_MASSON   Calculate within-subject error for individual groups.
%
%  This method can be used if one does not assume equal variance between
%  groups.
%
%  err = loftus_masson(dat)
%
%  INPUTS:
%     dat:  [subjects X groups] matrix of dependent measures.
%
%  OUTPUTS:
%      err:  [1 X groups] vector of error values.
%
%  Reference: Loftus, G. R. & Masson, MEJ (1994) PB&R 1(4):476-490

% Implementation based on Kahana96 pascal file, which is based on
% Loftus, G. R. & Masson, MEJ (1994) PB&R 1(4):476-490. This is
% valid for a within-subject design.

% normalize the data
grandMean = nanmean(dat(:));
subjMean = nanmean(dat, 2);
subjMean = repmat(subjMean, 1, size(dat, 2));
dat = dat - (subjMean - grandMean);

% compute sums
Tc = nansum(dat, 1);
Nsubj = sum(~isnan(dat), 1);
Ts = nansum(dat, 2);
Ncond = sum(~isnan(dat), 2);
T = nansum(dat(:));
SS_T = nansum(dat(:).^2);
Nvalid = sum(~isnan(dat(:)));

SS_C = sum(Tc.^2 ./ Nsubj);
SS_S = sum(Ts.^2 ./ Ncond);

% compute average number of valid subjects
NsubValid = sum(Nsubj) / size(dat, 2);
NcondValid = sum(Ncond) / size(dat, 1);

% compute final sums of squares
SS_T = SS_T - (T^2) / Nvalid;
SS_S = SS_S - (T^2) / Nvalid;
SS_C = SS_C - (T^2) / Nvalid;
SS_SxC = SS_T - SS_S - SS_C;

% mean square of the interaction
MS_SxC = SS_SxC / (Nvalid - NsubValid - NcondValid - 1);

% mean square w, i.e., variance between individuals (p.484)
MS_w = (nansum(dat.^2, 1) - ((Tc.^2) ./ Nsubj)) ./ (Nsubj - 1);

% p.484
estimator = (NcondValid / (NcondValid - 1)) * (MS_w - (MS_SxC ./ NcondValid));
  
%err = sqrt(estimator ./ Nsubj) * tinv(.975, size(dat, 1) - 1);
% NWM: seems like we need to adjust the critical value depending on the
% number of valid observations for a given condition
crit = NaN(1, size(dat, 2));
for i = 1:size(dat, 2)
  crit(i) = tinv(.975, Nsubj(i) - 1);
end
err = sqrt(estimator ./ Nsubj) .* crit;

%old implementation
% This script assumes that the variances for the different treatment groups
% are equal, in other words, the sphericity assumption. If this is not the
% case, then only errorbars can be computed for each contrast between treatments.

% numRows = size(dat,1);
% numCols = size(dat,2);
% D1data = reshape(dat,1,numRows*numCols);
% grandMean = mean(D1data);
% grandTotal = sum(D1data);
% % total sum squares
% SS_T = sum((D1data-grandMean).^2);

% % sum squares for rows (subjects)
% Srow = sum(dat,2);
% SSrow = sum(Srow.^2/numCols) - (grandTotal^2)/(numRows*numCols);
% % sum squares for columns (treatments)
% Scol = sum(dat,1);
% SScol = sum(Scol.^2/numRows) - (grandTotal^2)/(numRows*numCols);

% % compute the mean sum squares for the interaction between rows and columns
% SSint = SS_T - SSrow - SScol;
% df_int = (numRows*numCols-1) - (numRows-1) - (numCols-1);
% MSint = SSint/df_int;
% criterion = tinv(.975,df_int);

% % implementation of Loftus-Masson (1994), equation (2)
% err = sqrt(MSint/numRows)*criterion*ones(1,numCols);
