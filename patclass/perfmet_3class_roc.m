function [perfmet] = perfmet_3class_roc(acts,targs,scratchpad,varargin)
% PERFMET_3CLASS_ROC
%
%
% acts - nConds x nTimepoints
% targs - nConds x nTimepoints
%
% acts = rand(3,3000);
% targs = zeros(3,3000);
% targs(1,1:1000) = 1;
% targs(2,1001:2000) = 1;
% targs(3,2001:3000) = 1;
%
% pm = perfmet_3class_roc(acts, targs);


% check that there are 3 categories

% params
params.c_granularity = 100;

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
    
%     for k=1:size(temp,2)
%       if length(unique(temp(:,k))) < 3
%         keyboard
%       end
%     end
    
    % turn acts2d into a set of answers
    % which is largest
    [val, guesses] = max(temp);
    
    % are there ever any ties?
    if any(sum(temp==(ones(3,1) * val))>1)
      keyboard
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

% % what happens if we remove duplicate confusion matrices
% % the difference between R1,R2 vs R3 gets more stark!
% duplicate = false(1,size(confusion,2));
% for i=1:size(confusion,2)
%   if ~duplicate(i)
%     temp = confusion - (confusion(:,i) * ones(1,size(confusion,2)));
%     temp_dupe = sum(abs(temp))==0;
%     temp_dupe(i) = false;
%     duplicate = duplicate | temp_dupe;
%   end
% end
% keyboard

% we're creating a set of 6 polyhedra
vol = zeros(1,6);

% VOLUME 1: [1 5 9] 
% p(r1|e1), p(r2|e2), p(r3|e3)
v_inds = [1 5 9;
          1 8 6;
          2 4 9;
          2 6 7;
          3 4 8;
          3 5 7];

for i=1:6
  these = [confusion(v_inds(i,:),:) [0;0;0]]';
  surf(i).dt = DelaunayTri(these);
  [k vol(i)] = convexHull(surf(i).dt);
end

% Shannon entropy (?)
H = sum(vol.*log(vol)) * -1;

% Discriminability (should have min zero, doesn't)
D = log(6) - H;

perfmet.D = D;
perfmet.H = H;
perfmet.vol = vol;
perfmet.confusion = confusion;
perfmet.surf = surf;

%keyboard





