function jm = which_resource_manager()
%WHICH_JOB_MANAGER   Return the job manager for a cluster computing system
%
%  jm = which_resource_manager()
%
%  OUTPUTS:
%        jm:  a string containing the name of the job manager for a
%             cluster distributed computing system on UNIX ('none')
%             Possible job managers are:
%               SGE     - Sun Grid Engine
%               TORQUE  - Torque
%
% Note: It is assumed that the UNIX qsub command is in a
% subdirectory containing the name of the job manager.

if ~isunix
  warning(['Not running on a UNIX-based system. Setting job manager ' ...
           'to ''none''.'])
  jm = 'none';
else
  [s,w] = unix('which qsub');
  
  if isempty(w)
    warning(['No qsub command found. Setting job manager to ' ...
             '''none''.'])
    jm = 'none';
  else
    subdirs = regexp(w,'/','split');
    
    if any(strcmpi('sge',subdirs))
      jm = 'SGE';
      
    elseif any(strcmpi('torque',subdirs))
      jm = 'TORQUE';
      
    else
      % qsub command is found, but default job manager names are
      % not found on the path
      jm = 'none';
    end
    
  end
end
