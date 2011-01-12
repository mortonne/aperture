function fit = grid_search(params, fit_fcn, fit_inputs)
%GRID_SEARCH   Run a grid search of parameter space.
%
%  fit = grid_search(params, fit_fcn, fit_inputs)
%
%  INPUTS:
%      params:  structure of parameters, where each field
%               corresponds to one parameter, and gives a
%               cell array of values to search over for
%               that parameter.
%
%     fit_fcn:  function that takes a params structure as
%               the first input, and returns one number. The
%               output can be of any type, as long as it is
%               of length 1.
%
%  fit_inputs:  cell array of additional inputs to fit_fcn.
%
%  OUTPUTS:
%         fit:  matrix with one element for each combination
%               of parameters in the params structure. Contains
%               the output from fit_fcn for each cell of the
%               grid.
%
%  EXAMPLE:
%   % define ranges for the 'a', 'b', and 'c' parameters
%   params = struct('a',{num2cell(1:3)}, 'b',{{2}}, 'c',{num2cell(1:4)});
%
%   % define a function that produces a value for each combination
%   % of parameters (this function just gets the sum)
%   fit_fcn = @(x)(sum(cell2mat(struct2cell(x))));
%
%   % evaluate fit_fcn for all combinations of the parameters
%   fit = grid_search(params, fit_fcn);
%
%  See also grid2params.

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
if ~exist('params','var')
  error('You must pass a params structure.')
elseif any(~cellfun(@iscell, struct2cell(params)))
  error('Each search parameter field must be a cell array.')
elseif ~exist('fit_fcn','var')
  error('You must pass a function to evaluate on each cell of the grid.')
end
if ~exist('fit_inputs','var')
  fit_inputs = {};
end

% flatten the variables structure
values = struct2cell(params);
names = fieldnames(params);

% prepare the job
sm = findResource;
j.job = createJob;

% initialize a cell array of grid indices
i = repmat({1},1,length(values));

% run for-loops over all dimensions of the grid, and create
% a task for each cell
j = grid(j, i, 1, values, fit_fcn, fit_inputs, cell(1,length(values)), names);

% initialize the output grid
% removing so fit can be an array or a struct array
%fit = NaN(size(j.id));

% run all cells
submit(j.job);
wait(j.job);

% put the outputs into grid format
out = getAllOutputArguments(j.job);

% initialize the goodness-of-fit array
out_size = size(j.id);
if all(cellfun(@isnumeric, out))
  fit = NaN(out_size);
elseif all(cellfun(@iscell, out))
  fit = cell(out_size);
else
  error('fit_fcn %s is producing illegal output type %s.', ...
        func2str(fit_fcn), unique(cellfun(@class,out)))
end

for i=1:length(out)
  fit(j.id==i) = out{i};
end

function j = grid(j, i, n, c, f, f_in, values, names)
  % j - job
  % i - indices in the grid
  % n - variable number
  % c - cell array of possible values
  % f - function to be evaluated for each cell of the grid
  % f_in - additional inputs
  % values - cell array of valus for this iteration of
  %          all the for loops
  % names - cell array of variable names
  
  % loop over each value of this variable
  for k=1:length(c{n})
    % get this value
    values{n} = c{n}{k};
    i{n} = k;
    
    if n<length(c)
      % continue down the var cell...
      j = grid(j, i, n+1, c, f, f_in, values, names);
    else
      % this is the last variable
      params = cell2struct(values, names, 2);

      % create a task for this cell
      t = createTask(j.job, f, 1, {params, f_in{:}});
      j.id(i{:}) = t.ID;
      
      %j(i{:}) = f(params, f_in{:});
    end
  end
%endfunction
