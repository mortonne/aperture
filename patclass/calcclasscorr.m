function res = calcclasscorr(exp,patname,pcname,nscram)
%
%
%
%

% loop over subjects
for s=1:length(exp.subj)
  
  % get the pc results
  pat = getobj(exp.subj(s),'pat',patname);
  pc = getobj(pat,'pc',pcname);
  load(pc.file);
  
  % determine dimensions
  [nsel,nev,ncat] = size(posterior);
  
  res.subj(s).corrmat = NaN(nsel,ncat,ncat);
    
  for j=1:ncat % classifier output
    
    for k=1:ncat % target category
	  
      % loop over selection iterations
      for i=1:nsel
	
	this_post = squeeze(posterior(i,:,:));
	
	if sum(isnan(this_post(:)))<nev
	  
	  this_post(isnan(this_post))=0;
	  this_targ = testreg(i,:);	  
	  cattarg = this_targ==(k-1);
	  
	  res.subj(s).corrmat(i,j,k) = corr(cattarg',this_post(:,j));
	  

	  for scr=1:nscram
	    % scramble the category labels
	    scr_cattarg = cattarg(randsample(length(cattarg),length(cattarg)));
	    % recalculate the correlation
	    res.subj(s).scr_corrmat(scr,i,j,k) = corr(scr_cattarg',this_post(:,j));
	    
	  end
	else
	  res.subj(s).corrmat(i,:,:) = NaN;
	end % if nan
      end % i nsel
      
      
      % calculate the cross-sel scrambled corrmat
      res.subj(s).scr_cs_corrmat = squeeze(nanmean(res.subj(s).scr_corrmat,2));

      
    end % if k targ cat
  end % j class out
  
  % calculate the cross-sel corrmat
  res.subj(s).cs_corrmat = squeeze(nanmean(res.subj(s).corrmat));
  
  % calculate the significance of each cs_corrmat cell
  for j=1:ncat
    for k=1:ncat

      res.subj(s).cs_pval(j,k) = ...
	  1-(sum(res.subj(s).cs_corrmat(j,k)>res.subj(s).scr_cs_corrmat(:,j,k))/nscram);
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
  res.subj(s).ondiag = mean(res.subj(i).cs_corrmat(indondiag));
  res.subj(s).offdiag = mean(res.subj(i).cs_corrmat(indoffdiag));
  
  res.subj(s).onoff = res.subj(s).ondiag - res.subj(s).offdiag;
  
  % ondiag - offdiag, perm data
  for scr = 1:nscram
    
    this_scr = squeeze(res.subj(s).scr_cs_corrmat(scr,:,:));
    ondiag = mean(res.subj(i).cs_corrmat(indondiag));
    offdiag = mean(res.subj(i).cs_corrmat(indoffdiag));
    scr_onoff(scr) = ondiag - offdiag;
    
  end
  
  res.subj(s).onoff_pval = ...
	  1-(sum(res.subj(s).onoff>scr_onoff)/nscram);
  
end

res.meancorrmat = squeeze(mean(res.corrmat,1));
