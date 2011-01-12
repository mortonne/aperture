function stat = init_stat(name,file,source,params)
%INIT_STAT   Initialize a structure to hold metadata about a statistic.
%
%  stat = init_stat(name, file, source, params)
%
%  Stat objects are meant to be general containers for any kind of
%  statistic, and intentionally don't have any real constraints. They
%  have a different name than, say, fig objects only to make them 
%  easier to organize; there really isn't any difference besides the
%  default inclusion of a "params" field.
%
%  INPUTS:
%     name:  string identifier for this object.
%
%     file:  path to a MAT-file where statistic-related variables are 
%            saved.
%
%   source:  name of the object from which this statistic is derived.
%
%   params:  structure containing the options used in calculating this
%            statistic.
%
%  OUTPUTS:
%     stat:  a standard "stat" object. Fields are:
%             'name'
%             'file'
%             'source'
%             'params'

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

% input checks
if ~exist('name','var')
  name = '';
end
if ~exist('file','var')
  file = '';
end
if ~exist('source','var')
  source = '';
end
if ~exist('params','var')
  params = struct();
end

% make the structure
stat = struct('name',name, 'file',file, 'source',source, 'params',params);
