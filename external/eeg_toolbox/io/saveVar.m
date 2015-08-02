function saveVar(var_to_save,filename)
%SAVEVAR - Save a variable to a file.
%
% Saves any workspace variable to a file.  You can then use loadVar
% to load it later..
%
% FUNCTION:
%   saveVar(invar,filename)
%
% INPUT ARGS:
%   var = rec_events;  % Events structure to save
%   filename = 'events/rec_events.mat'; % file to save to
%
%



if str2num(version('-release')) >= 14
  save(filename,'-V6','var_to_save');
else
  save(filename,'var_to_save');
end

