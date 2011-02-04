%TEST_PATBINS   Unit tests for patBins.
%
%  runner = mlunit.text_test_runner(1,1);
%loader = mlunit.test_loader;
%run(runner, load_tests_from_test_case(loader, 'test_patBins'));

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

classdef test_patBins < mlunit.test_case
  properties
    pat
  end

  methods
    function self = test_patBins(varargin)
      self = self@mlunit.test_case(varargin{:});
      
      event = struct('type', 'test', ...
                     'a', {1 1 1 1 1 1 2 2 2 2}, ...
                     'b', {1 2 3 4 5 6 7 8 9 10}, ...
                     'c', {3 3 3 2 2 2 1 1 1 1}, ...
                     'd', {1 1 1 1 1 2 2 2 2 2});
      ev = init_ev('test_events');
      chan = struct('number', num2cell(1:5), ...
                    'label', cellfun(@num2str, num2cell(1:5), ...
                                     'UniformOutput', false));
      
      % initialize test data
      pat = init_pat('test_pattern', '', 'subj007', struct, ev, chan);
      pat = set_mat(pat, rand(10, 5));
      pat.dim = set_dim(pat.dim, 'ev', event);
      pat.dim = set_dim(pat.dim, 'chan', chan);
      self.pat = pat;
    end
    
    function self = test_event_bins_field(self)
      % event bins with one factor
      pat = self.pat;
      [pat, bins] = patBins(pat, 'eventbins', 'a', ...
                            'eventbinlabels', {'one' 'two'});
      events = get_dim(pat.dim, 'ev');

      % events
      mlunit.assert(~isfield(events, 'b'), ...
                    'non-singular field b not removed.');
      mlunit.assert(isequal([events.a], [1 2]));
      mlunit.assert(isequal({events.type}, {'test', 'test'}));
      mlunit.assert(isequal({events.label}, {'one' 'two'}));
      mlunit.assert(isequal([events.n], [6 4]));
      
      % bins
      mlunit.assert(isequal(bins, {{[1:6]' [7:10]'} [] [] []}));
    end
    
    function self = test_event_bins_filt(self)
      % event bins with a set of filters
      pat = self.pat;
      [pat, bins] = patBins(pat, 'eventbins', {'c == 2' 'c == 1' 'c == 3'}, ...
                            'eventbinlabels', {'b' 'a' 'c'});
      events = get_dim(pat.dim, 'ev');
      
      % events
      mlunit.assert(isequal([events.c], [2 1 3]));
      mlunit.assert(isequal({events.label}, {'b' 'a' 'c'}));
      mlunit.assert(isequal([events.n], [3 4 3]));
      
      % bins
      mlunit.assert(isequal(bins, {{[4:6]' [7:10]' [1:3]'} [] [] []}));
    end
    
    function self = test_event_bins_field_conj(self)
      % events bins from conjunction of two fields
      pat = self.pat;
      [pat, bins] = patBins(pat, 'eventbins', {'a' 'c'}, ...
                            'eventbinlevels', {{'one' 'two'}, ...
                            {'one' 'two' 'three'}});
      events = get_dim(pat.dim, 'ev');

      % events
      mlunit.assert(~isfield(events, 'b'), ...
                    'non-singular field b not removed.');
      mlunit.assert(isequal([events.a], [1 1 2]));
      mlunit.assert(isequal([events.c], [2 3 1]));
      mlunit.assert(isequal({events.factor1}, {'one' 'one' 'two'}));
      mlunit.assert(isequal({events.factor2}, {'two' 'three' 'one'}));
      mlunit.assert(isequal([events.n], [3 3 4]));
      mlunit.assert(isequal({events.label}, ...
                           {'one two' 'one three' 'two one'}));
      
      % bins
      mlunit.assert(isequal(bins, {{[4:6]' [1:3]' [7:10]'} [] [] []}))
    end

    function self = test_event_bins_field_conj_nol(self)
      % events bins from conjunction of two fields
      pat = self.pat;
      [pat, bins] = patBins(pat, 'eventbins', {'a' 'c'});
      events = get_dim(pat.dim, 'ev');

      % events
      mlunit.assert(~isfield(events, 'b'), ...
                    'non-singular field b not removed.');
      mlunit.assert(isequal([events.a], [1 1 2]));
      mlunit.assert(isequal([events.c], [2 3 1]));
      mlunit.assert(isequal({events.factor1}, {'1' '1' '2'}));
      mlunit.assert(isequal({events.factor2}, {'2' '3' '1'}));
      mlunit.assert(isequal([events.n], [3 3 4]));
      mlunit.assert(isequal({events.label}, ...
                           {'1 2' '1 3' '2 1'}));
      
      % bins
      mlunit.assert(isequal(bins, {{[4:6]' [1:3]' [7:10]'} [] [] []}))
    end
    
    function self = test_event_bins_filt_conj(self)
      % event bins from conjunction of two sets of filters
      pat = self.pat;
      factor1 = {'d == 1' 'd == 2'};
      labels1 = {'d is one' 'd is two'};
      factor2 = {'mod(b, 2) == 0', 'mod(b, 2) == 1'};
      labels2 = {'b is even' 'b is odd'};
      [pat, bins] = patBins(pat, 'eventbins', {factor1, factor2}, ...
                            'eventbinlevels', {labels1, labels2});
      events = get_dim(pat.dim, 'ev');
      
      % events
      mlunit.assert(~isfield(events, 'b'), ...
                    'non-singular field b not removed.');
      mlunit.assert(isequal({events.a}, {1 1 [] 2}));
      mlunit.assert(isequal({events.c}, {[] [] [] 1}));
      mlunit.assert(isequal({events.factor1}, ...
                            {'d is one' 'd is one' 'd is two' 'd is two'}));
      mlunit.assert(isequal({events.factor2}, ...
                            {'b is even' 'b is odd' 'b is even' 'b is odd'}));
      mlunit.assert(isequal([events.n], [2 3 3 2]));
      mlunit.assert(isequal({events.label}, ...
                           {'d is one b is even' 'd is one b is odd', ...
                            'd is two b is even' 'd is two b is odd'}));
      
      % bins
      mlunit.assert(isequal(bins, ...
                            {{[2 4]' [1 3 5]' [6 8 10]' [7 9]'} [] [] []}));
    end
    
    function self = test_event_bins_filt_conj_nol(self)
      % event bins from conjunction of two sets of filters
      pat = self.pat;
      factor1 = {'d == 1' 'd == 2'};
      factor2 = {'mod(b, 2) == 0', 'mod(b, 2) == 1'};
      [pat, bins] = patBins(pat, 'eventbins', {factor1, factor2});
      events = get_dim(pat.dim, 'ev');
      
      % events
      mlunit.assert(~isfield(events, 'b'), ...
                    'non-singular field b not removed.');
      mlunit.assert(isequal({events.a}, {1 1 [] 2}));
      mlunit.assert(isequal({events.c}, {[] [] [] 1}));
      mlunit.assert(isequal({events.factor1}, ...
                            {'d == 1' 'd == 1' 'd == 2' 'd == 2'}));
      mlunit.assert(isequal({events.factor2}, ...
                            {'mod(b, 2) == 0' 'mod(b, 2) == 1' ...
                             'mod(b, 2) == 0' 'mod(b, 2) == 1'}));
      mlunit.assert(isequal([events.n], [2 3 3 2]));
      mlunit.assert(isequal({events.label}, ...
                           {'d == 1 mod(b, 2) == 0' 'd == 1 mod(b, 2) == 1', ...
                            'd == 2 mod(b, 2) == 0' 'd == 2 mod(b, 2) == 1'}));
      
      % bins
      mlunit.assert(isequal(bins, ...
                            {{[2 4]' [1 3 5]' [6 8 10]' [7 9]'} [] [] []}));
    end
    
  end
end