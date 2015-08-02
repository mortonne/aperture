function p=eeganalparams(field)
%EEGANALPARAMS - Return an EEG analysis parameter.
%
% This function returns the desired parameter value from the 
% EEG analysis parameter file, which is located in:
%
%   ~/eeg/eeganalparams.txt
%
% Use this file to keep parameters used for all analyses.  For
% example: 
%
% freqs (2^(1/8)).^(8:48)
% width 6
% 
% As you can see, the format of the file is to list the parameter
% name, followed by the value for that field.  One field per line.
%
%
% FUNCTION: 
%   p = eeganalparams(field)
%
% INPUT ARGS:
%   field = 'freqs';  % the desired field
%
% OUTPUT ARGS:
%   p - The value of the parameter
%

p=[]; % returns an empty matrix if not a known field and not found

in=fopen('~/eeg/eeganalparams.txt','rt');
if(in~=-1)
  done=0;
  f=0;
  while( (~isempty(f)) & ~done)
    f=fscanf(in,'%s',1); 
    %v=fscanf(in,'%f',1);
    v = fgetl(in);
    if(strcmp(f,field)) 
      if isstr(v)
	v = eval(v);
      end
      
      p=v; 
      done=1; 
    end;

  end % while not done
  
  % close the file
  fclose(in);
end
% default is to return the default value assigned at the top


