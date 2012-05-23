function [perfmet] = perfmet_class_roc(acts,targs,scratchpad,varargin)
% PERFMET_CLASS_ROC - ROC-based performance metric to calculate
% AUC when there are 2 classes.
%
%
% acts - nConds x nTimepoints
% targs - nConds x nTimepoints must be BINARY
%
%
% pm = perfmet_2class_roc(acts, targs);
%

warning('off', 'MATLAB:griddata:DuplicateDataPoints');

% initialize an empty perfmet
perfmet.perf = NaN;
perfmet.scratchpad = [];

% check that there are 2 categories
if size(acts,1)~=2
  error('perfmet_class_gcm requires 2 categories.');
elseif any(~any(targs, 2))
  warning('not all classes are represented. D is undefined.\n')
  return
end

[x,y,t,auc] = perfcurve(targs(1,:),acts(1,:),true);

% AUC is the performance metric
perfmet.perf = auc;
perfmet.scratchpad = [];

warning('on', 'MATLAB:griddata:DuplicateDataPoints');

