function [perfmet] = perfmet_3class_gcm(acts,targs,scratchpad,varargin)
% PERFMET_3CLASS_GCM
%
%
% acts - nConds x nTimepoints
% targs - nConds x nTimepoints
%
% % CASE WHERE THERE IS NO INFO
% acts = rand(3,3000);
% targs = zeros(3,3000);
% targs(1,1:1000) = 1;
% targs(2,1001:2000) = 1;
% targs(3,2001:3000) = 1;
%
% pm = perfmet_3class_gcm(acts, targs);
%
% % CASE WHERE THERE IS SOME INFO
% acts = rand(3,3000);
% targs = zeros(3,3000);
% acts(1,1:1000) = acts(1,1:1000) + 0.1;
% acts(2,1001:2000) = acts(2,1001:2000) + 0.1;
% acts(3,2001:3000) = acts(3,2001:3000) + 0.1;
% targs(1,1:1000) = 1;
% targs(2,1001:2000) = 1;
% targs(3,2001:3000) = 1;
%
% pm = perfmet_3class_gcm(acts, targs);


% check that there are 3 categories

% luce choice the acts
temp = ones(3,1) * sum(acts);
lc_acts = acts ./ temp;

% params
params.c_granularity = 20;

n_obs = size(acts,2);

[val targets] = max(targs);


% sweep over (c1,c2, c3)
% what's the range of acts2d
maxact = max(acts, [], 2);
minact = min(acts, [], 2);

c_range = zeros(3,params.c_granularity);
c_range(1,:) = linspace(0, 1, params.c_granularity);
c_range(2,:) = linspace(0, 1, params.c_granularity);
c_range(3,:) = linspace(0, 1, params.c_granularity);

% ep = 0.01;
% c_range = zeros(3,params.c_granularity);
% c_range(1,:) = linspace(minact(1)-ep, maxact(1)+ep, params.c_granularity);
% c_range(2,:) = linspace(minact(2)-ep, maxact(2)+ep, params.c_granularity);
% c_range(3,:) = linspace(minact(3)-ep, maxact(3)+ep, params.c_granularity);

% cat3 is right when zero is the largest
temp = zeros(3, n_obs);
confusion = zeros(9,size(c_range,2)^3);
crit_ind = 0;
for i = c_range(1,:)
  for j = c_range(2,:)
    for k = c_range(3,:)
    
      crit_ind = crit_ind + 1;
      c = [i; j; k];
    
      % subtract criteria off of acts
      temp = acts - (c * ones(1, n_obs));
        
      % turn acts2d into a set of answers
      % which is largest
      [val, guesses] = max(temp);
    
      % are there ever any ties?
      % maybe in the real data, not yet in synth
      % NOTE: deal with ties!

      %if any(sum(temp==(ones(3,1) * val))>1)
      %  keyboard
      %end
      
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
  fprintf('~');
end
fprintf('\n');
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

res = 20;
linpts = linspace(0,1,res);
[Xinterp, Yinterp] = meshgrid(linpts, linpts);

for i=1:6

  these = confusion(v_inds(i,:),:)';

  Zinterp = griddata(these(:,1), these(:,2), these(:,3), ...
                     Xinterp, Yinterp);

  Zinterp(isnan(Zinterp)) = 0;
  vol(i) = dblquad(@(a,b)interp2(Xinterp,Yinterp,Zinterp,a,b,'cubic'),0,1,0,1);

end

% Shannon entropy (?)
H = sum(vol.*log(vol)) * -1;

% Discriminability (should have min zero, doesn't)
D = log(6) - H;

perfmet.D = D;
perfmet.H = H;
perfmet.vol = vol;
perfmet.confusion = confusion;
%perfmet.surf = surf;

%keyboard





