function subj = merge_subjs(subj1, subj2)
%MERGE_SUBJS   Merge two subject structures.
%
%  subj = merge_subjs(subj1, subj2)
%
%  Merge two subjects structures. If two subjects have the same 
%  ID, they are assumed to be the same person, and all information
%  is taken from the instance in subj1.
%
%  If subj2 contains any objects (i.e., sub-structures that have
%  a "name" field), the objects will be added to subj. If subj1
%  has an object of the same type and name, it will take
%  precedence over the version in subj2.
%
%  For session objects, criteria for session uniqueness is the 
%  "dir" field. If, for a given subject, session numbers overlap 
%  where session directories do not, the number field will be 
%  overwritten to become the index of the session, where subj1 
%  sessions are placed first, followed by subj2 sessions.
%
%  INPUTS:
%    subj1:  a subject structure. Takes priority over subj2.
%
%    subj2:  a subject structure containing information to be
%            added to subj1.
%
%  OUTPUTS:
%     subj:  merged subject structure.

% check subj1
if ~exist('subj1','var')
  error('You must pass a subject structure.')
elseif isempty(subj1) && ~isempty(subj2)
  subj = subj2;
  return
elseif ~isfield(subj1,'id')
  error('Subject structure 1 must have an "id" field.')
end

% check subj2
subj = subj1;
if ~exist('subj2','var')
  % nothing to do
  return
elseif ~isstruct(subj2)
  error('subj2 must be a structure.')
elseif ~isfield(subj2,'id')
  error('Subject structure 2 must have an "id" field.')
end

% get subjects that are in set2 but not in set1
[c,i] = setdiff({subj2.id}, {subj1.id});
subjtoadd = subj2(i);

% add them
for thissubj=subjtoadd
  subj = setobj(subj, thissubj);
end

% get subjects that are in both
[clones,i1,i2] = intersect({subj1.id}, {subj2.id});

% get all unique sessions from either version of this subject
for i=1:length(clones)
  % get the versions of this subject
  clone1 = subj1(i1(i));
  clone2 = subj2(i2(i));
  
  % the version from subj1 takes precedence
  new_subj = clone1;
  
  % find sessions that are in sess2 but not sess1
  [c,i] = setdiff({clone2.sess.dir}, {clone1.sess.dir});
  if ~isempty(i)
    sesstoadd = clone2.sess(i);
    for sess=sesstoadd
      new_subj = setobj(new_subj, 'sess', sess);
    end

    % fix the session numbers if necessary
    if any(ismember([sesstoadd.number], [clone1.sess.number]))
      c = num2cell(1:length(new_subj.sess));
      [new_subj.sess.number] = deal(c{:});
    end
  end

  % read objects from
  fnames = fieldnames(clone2);
  for i=1:length(fnames)
    f = fnames{i};
    if isfield(clone2.(f), 'name')
      % 2 has a field we need to consider adding
      if isfield(clone1,f)
        objs = clone1.(f);
        temp = clone2;
        for obj=objs
          % 1 > 2
          temp = setobj(clone2, f, obj);
        end
        new_subj.(f) = temp.(f);
      else
        % 1 doesn't have any of this object; just use 2
        new_subj.(f) = clone2.(f);
      end
    end
  end

  % modify this subject
  subj = setobj(subj, new_subj);
end

% sort the new subjects in
[ids,sort_ind] = sort({subj.id});
subj = subj(sort_ind);
