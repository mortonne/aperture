function [perfmet] = perfmet_3class_roc(acts,targs,scratchpad,varargin)
% PERFMET_3CLASS_ROC - SDT-based performance metric to calculate
% discriminability when there are 3 classes.
%
% Discriminability metric is from:
%  Scurfield (1998) Journal of Math. Psych., 42, 5-31.
%
% acts - nConds x nTimepoints
% targs - nConds x nTimepoints
%
% % EXAMPLE CASE WHERE THERE IS NO CAT. STRUCTURE
%
% acts = rand(3,3000);
% targs = zeros(3,3000);
% targs(1,1:1000) = 1;
% targs(2,1001:2000) = 1;
% targs(3,2001:3000) = 1;
%
% pm = perfmet_3class_roc(acts, targs);
%
% % EXAMPLE CASE WHERE THERE IS SOME CAT. STRUCTURE
%
% acts = rand(3,3000);
% targs = zeros(3,3000);
% acts(1,1:1000) = acts(1,1:1000) + 0.1;
% acts(2,1001:2000) = acts(2,1001:2000) + 0.1;
% acts(3,2001:3000) = acts(3,2001:3000) + 0.1;
% targs(1,1:1000) = 1;
% targs(2,1001:2000) = 1;
% targs(3,2001:3000) = 1;
%
% pm = perfmet_3class_roc(acts, targs);
%


% check that there are 3 categories
if size(acts,1)~=3
  error('perfmet_3class_gcm requires 3 categories.');
end

% params
defaults.c_granularity = 20;
defaults.interp_res = 20;
defaults.ignore_1ofn = true;
params = propval(varargin, defaults);

n_obs = size(acts,2);

[val targets] = max(targs);

% turn the 3 dim acts into a 2-d vector by subtracting off the 3rd
% dimension

acts2d = acts(1:2,:);
acts2d = acts2d - (ones(2,1) * acts(3,:));

% sweep over (c1,c2)
% what's the range of acts2d
maxact = max(acts2d, [], 2);
minact = min(acts2d, [], 2);

% is it important to start just beyond the min and max?
ep = 0.1;
c_range = zeros(2,params.c_granularity);
c_range(1,:) = linspace(minact(1)-ep, maxact(1)+ep, params.c_granularity);
c_range(2,:) = linspace(minact(2)-ep, maxact(2)+ep, params.c_granularity);

% cat3 is right when zero is the largest
temp = zeros(3, n_obs);
crit_ind = 0;
for i = c_range(1,:)
  for j = c_range(2,:)
    
    crit_ind = crit_ind + 1;
    c = [i; j];
    
    % subtract criteria off of acts2d
    temp(1:2,:) = acts2d - (c * ones(1, n_obs));
        
    % turn acts2d into a set of answers
    % largest one (relative to its criterion wins)
    % if 1 and 2 are negative, 3 wins
    [val, guesses] = max(temp);
    
    % check for a tie
    tied_cols = sum(temp==(ones(3,1) * val))>1;
    if any(tied_cols)
      % randomly choose an answer for each tied ind
      % from among the tied inds
      tied_inds = temp==(ones(3,1) * val);
      tied_inds(:,sum(tied_inds)==1) = 0;
      for t = 1:size(tied_inds,2)
        if sum(tied_inds(:,t))>1
          guesses(t) = randsample(find(tied_inds(:,t)),1);
        end
      end
    end
    
    % calculate the 3x3 confusion matrix
    % targets, guesses
    for e = 1:3
      these_e = targets==e;
      n_e = sum(these_e);
      for r = 1:3
        % how many times was this response made, given this target
        confusion(e + ((r-1) * 3), crit_ind) = ...
            sum(guesses(these_e)==r) / n_e;
        
      end
    end
    
  end
end

% we're creating a set of 6 polyhedra
vol = zeros(1,6);

% Define the volumes, e.g.,
% VOLUME 1: [1 5 9] 
% p(r1|e1), p(r2|e2), p(r3|e3)
v_inds = [1 5 9;
          1 8 6;
          2 4 9;
          2 6 7;
          3 4 8;
          3 5 7];

% initialize interpolation
linpts = linspace(0,1,params.interp_res);
[Xinterp, Yinterp] = meshgrid(linpts, linpts);

% calculate the volume of the 6 ROC surfaces
for i=1:6
  these = confusion(v_inds(i,:),:)';
  Zinterp = griddata(these(:,1), these(:,2), these(:,3), ...
                     Xinterp, Yinterp);
  Zinterp(isnan(Zinterp)) = 0;
  vol(i) = dblquad(@(a,b)interp2(Xinterp,Yinterp,Zinterp,a,b,'cubic'),0,1,0,1);
end

% Shannon entropy of the 6 volumes
H = sum(vol.*log(vol)) * -1;

% Scurfield's discriminability metric
% min 0, max log(6)
D = log(6) - H;

% D, discriminability is the performance metric
perfmet.perf = D;
perfmet.scratchpad = [];
% perfmet.scratchpad.confusion = confusion;
% perfmet.scratchpad.vol = vol;
% perfmet.scratchpad.H = H;





