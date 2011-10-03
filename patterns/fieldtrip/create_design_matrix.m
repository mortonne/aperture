function design = create_design_matrix(events, reg_defs)
%CREATE_DESIGN_MATRIX   Create a design matrix for FieldTrip.
%
%  design = create_design_matrix(events, reg_defs)
%
%  INPUTS:
%    events:  events structure.
%
%  reg_defs:  cell array of inputs to make_index. Each cell will
%             correspond to one row in the design matrix.
%
%  OUTPUTS:
%    design:  [factors X events] design matrix, compatible with
%             FieldTrip functions.

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

n_factors = length(reg_defs);
n_events = length(events);
design = NaN(n_factors, n_events);
for i = 1:n_factors
  design(i,:) = make_index(getStructField(events, reg_defs{i}))';
end

