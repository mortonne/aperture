function res = calcclasscorr(subj, pat_name, pc_name, n_scram)
%CALCCLASSCORR   Calculate correlation between classifier output and regressor.
%
%  res = calcclasscorr(subj, pat_name, pc_name, n_scram)
%
%  INPUTS:
%      subj:  a vector of subject objects.
%
%  pat_name:  name of the pattern the classifier was tested on.
%
%   pc_name:  name of the patclass object.
%
%   n_scram:  
%
%  OUTPUTS:
%       res:  a results structure.
%
%  RES FIELDS:
%   subj        - 
%   corrmat     - 
%   meancorrmat - 
%   pcorr       - 
%   onoff       - 
%
%  RES.SUBJ FIELDS:
%   corrmat
%   scr_corrmat
%   scr_cs_corrmat
%   cs_corrmat
%   cs_pval
%   ondiag
%   offdiag
%   onoff
%   onoff_pval

% loop over subjects
for s=1:length(subj)
  % initialize subject results
  res.subj(s).id = subj(s).id;

  % get the pc results
  pat = getobj(subj(s), 'pat', pat_name);
  pc = getobj(pat, 'pc', pc_name);
  load(pc.file);

  % determine dimensions
  [nsel, nev, ncat] = size(posterior);

  res.subj(s).corrmat = NaN(nsel,ncat,ncat);

  for j=1:ncat % classifier output
    for k=1:ncat % target category

      % loop over selection iterations
      for i=1:nsel
        this_post = squeeze(posterior(i,:,:));

        if nnz(isnan(this_post)) < nev
          this_post(isnan(this_post)) = 0;
          this_targ = testreg(i,:);
          cattarg = this_targ == (k-1);

          res.subj(s).corrmat(i,j,k) = corr(cattarg', this_post(:,j));

          for scr=1:nscram
            % scramble the category labels
            scr_cattarg = cattarg(randsample(length(cattarg), length(cattarg)));
            % recalculate the correlation
            res.subj(s).scr_corrmat(scr,i,j,k) = corr(scr_cattarg', this_post(:,j));
          end
        else
          % posterior for this iteration is all naN
          res.subj(s).corrmat(i,:,:) = NaN;
        end % if nan
      end % i nsel

      % calculate the cross-sel scrambled corrmat
      res.subj(s).scr_cs_corrmat = squeeze(nanmean(res.subj(s).scr_corrmat,2));

    end % if k targ cat
  end % j class out
 
  % calculate the cross-sel corrmat
  res.subj(s).cs_corrmat = permute(nanmean(res.subj(s).corrmat, 1), [2 3 1]);

  % calculate the significance of each cs_corrmat cell
  for j=1:ncat
    for k=1:ncat
      res.subj(s).cs_pval(j,k) = ...
      1-(nnz(res.subj(s).cs_corrmat(j,k)>res.subj(s).scr_cs_corrmat(:,j,k))/nscram);
    end
  end
end % s subj

indondiag = logical(eye(3));
indoffdiag = logical(~eye(3));

% for each subject calculate mean corrmat
for s=1:length(res.subj)

  % aggregate correlations
  res.corrmat(s,:,:) = res.subj(s).cs_corrmat;

  % ondiag - offdiag, actual data
  res.subj(s).ondiag = mean(res.subj(s).cs_corrmat(indondiag));
  res.subj(s).offdiag = mean(res.subj(s).cs_corrmat(indoffdiag));
  
  res.subj(s).onoff = res.subj(s).ondiag - res.subj(s).offdiag;
  
  % ondiag - offdiag, perm data
  for scr = 1:nscram
    this_scr = squeeze(res.subj(s).scr_cs_corrmat(scr,:,:));
    ondiag = mean(this_scr(indondiag));
    offdiag = mean(this_scr(indoffdiag));
    scr_onoff(scr) = ondiag - offdiag;
  end
  
  res.subj(s).onoff_pval = ...
	  1-(sum(res.subj(s).onoff>scr_onoff)/nscram);
end

res.meancorrmat = squeeze(mean(res.corrmat,1));
