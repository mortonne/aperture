function pat = init_pat(name, file, source, params, ev, chan, time, freq)
%INIT_PAT   Initialize a structure to hold metadata about a pattern.
%
%  pat = init_pat(name, file, source, params, ev, chan, time, freq)
%
%  Initializes a "pat" object, which holds metadata about a pattern.
%
%  INPUTS:
%     name:  string identifier.
%
%     file:  file where the pattern matrix is stored.
%
%   source:  name of the object from which this pattern is derived (usually 
%            a subj structure).
%
%   params:  structure containing the options used to create this pattern.
%
%       ev:  structure with information about the events dimension.
%
%     chan:  channels dimension.
%
%     time:  time dimension.
%
%     freq:  frequency dimension.
%
%  OUTPUTS:
%      pat:  a standard "pat" object.

% Copyright 2007-2011 Neal Morton, Sean Polyn, Zachary Cohen, Matthew Mollison.
%
% This file is part of EEG Analysis Toolbox.
%
% EEG Analysis Toolbox is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% EEG Analysis Toolbox is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser General Public License
% along with EEG Analysis Toolbox.  If not, see <http://www.gnu.org/licenses/>.

% defaults
if ~exist('name', 'var')
  name = '';
end
if ~exist('file', 'var')
  file = '';
end
if ~exist('source','var')
  source = '';
end
if ~exist('params', 'var')
  params = struct();
end

if isfield(ev, 'ev')
  % assume a dim struct was passed in
  dim = ev;
  clear ev
else
  % make standard blank dimensions
  dim = struct;
  dim_names = {'ev' 'chan' 'time' 'freq'};
  for i = 1:length(dim_names)
    dim.(dim_names{i}) = init_dim(dim_names{i});
  end

  % create default structures for each dimension
  if ~exist('ev', 'var')
    ev = struct('type', '');
  end
  if ~exist('chan', 'var')
    chan = struct('number', [],  'label', '');
  end
  if ~exist('time', 'var')
    time = init_time();
  end
  if ~exist('freq', 'var')
    freq = init_freq();
  end

  % set the content of each dimension
  dim = set_dim(dim, 'ev', ev, 'ws');
  dim = set_dim(dim, 'chan', chan, 'ws');
  dim = set_dim(dim, 'time', time, 'ws');
  dim = set_dim(dim, 'freq', freq, 'ws');
end
  
% make the pat structure
pat = struct('name', name, 'file', '', 'source', source, ...
             'params', params, 'dim', dim);

% if we assign this in call to struct, pat will be made a vector structure
pat.file = file;
