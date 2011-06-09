%TEST_TRAINTEST   Unit test for traintest.

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

classdef test_traintest < mlunit.test_case
  properties
    targets
    trainpattern
    testpattern
    traintargets
    testtargets
    params
  end

  methods
    function self = test_traintest(varargin)
      self = self@mlunit.test_case(varargin{:});

      rand('state', 1);
      
      self.targets = [1 1 1 1 0 0 0 0 0 0
                      0 0 0 0 1 1 1 0 0 0
                      0 0 0 0 0 0 0 1 1 1];
      self.targets = self.targets';
      self.trainpattern = rand(10, 20);
      self.testpattern = rand(10, 20);
      self.traintargets = self.targets(randsample(10,10),:);
      self.testtargets = self.targets(randsample(10,10),:);
      self.params = struct('f_train', @train_logreg, ...
                           'train_args', {struct('penalty', 10)}, ...
                           'f_test', @test_logreg, ...
                           'f_perfmet', @perfmet_maxclass);
    end

    function self = test_good_input(self)
      res = traintest(self.testpattern, self.trainpattern, ...
                      self.testtargets, self.traintargets, self.params);
      
      mlunit.assert(all(~res.train_idx));
      mlunit.assert(all(res.test_idx));
    end
    
    function self = test_empty_pattern(self)
      res = traintest(self.testpattern, [], ...
                      self.testtargets, self.traintargets, self.params);

      % check things that should be defined regardless
      mlunit.assert(all(~res.train_idx));
      mlunit.assert(all(res.test_idx));
      mlunit.assert(all(isnan(res.acts(:))))
      mlunit.assert(all(~isnan(res.targs(:))))
      mlunit.assert(all(isnan(res.perf)))
    end
    
    function self = test_nan_pattern(self)
      res = traintest(self.testpattern, NaN(size(self.trainpattern)), ...
                      self.testtargets, self.traintargets, self.params);

      % check things that should be defined regardless
      mlunit.assert(all(~res.train_idx));
      mlunit.assert(all(res.test_idx));
      mlunit.assert(all(isnan(res.acts(:))))
      mlunit.assert(all(~isnan(res.targs(:))))
      mlunit.assert(all(isnan(res.perf)))
    end
  end
end
