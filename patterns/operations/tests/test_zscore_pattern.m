%TEST_ZSCORE_PATTERN   Unit tests for zscore_pattern.
%
%  runner = mlunit.text_test_runner(1,1);
%  loader = mlunit.test_loader;
%  run(runner, load_tests_from_test_case(loader, 'test_zscore_pattern'));

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

classdef test_zscore_pattern < mlunit.test_case
  properties
    pat
    subj
  end

  methods
    function self = test_zscore_pattern(varargin)
      self = self@mlunit.test_case(varargin{:});
      
      event = struct('type', 'test', ...
                     'a', {1 1 1 2 2 2 2 3 3 3});
      ev = init_ev('test_events');
      chan = struct('number', num2cell(1:5), ...
                    'label', cellfun(@num2str, num2cell(1:5), ...
                                     'UniformOutput', false));
      ms_vals = -100:2:998;
      time = init_time(ms_vals);
      
      % initialize test data
      dummy_file = './temp/test_pattern.mat';
      pat = init_pat('test_pattern', dummy_file, 'subj007', ...
                     struct, ev, chan);
      
      % start with random 0-1000
      pattern = rand(10, 5, length(ms_vals)) * 1000;
      
      % add linear trend over time
      pattern = pattern + repmat(permute(10 * ms_vals, [1 3 2]), ...
                                 [size(pattern, 1) size(pattern, 2) 1]);

      % add random variation for each channel
      r = rand(1, size(pattern, 2), 1, size(pattern, 4)) * 2000;
      pattern = pattern + repmat(r, [size(pattern, 1) 1 size(pattern, 3) 1]);
      
      pat = set_mat(pat, pattern, 'ws');
      pat.dim = set_dim(pat.dim, 'ev', event);
      pat.dim = set_dim(pat.dim, 'chan', chan);
      pat.dim = set_dim(pat.dim, 'time', time);
      self.pat = pat;
      
      subj = struct('id', 'subj007');
      subj = setobj(subj, 'pat', pat);
      self.subj = subj;
    end
    
    function self = test_zscore_range(self)
      % run z-transform
      subj = zscore_pattern(self.subj, self.pat.name, [-100 0], ...
                            'event_bins', 'a', 'save_mats', false);
      
      % test the resulting pattern
      pattern = get_mat(subj.pat);
      events = get_dim(subj.pat.dim, 'ev');
      times = get_dim_vals(subj.pat.dim, 'time');
      sessions = unique([events.a]);
      for i = 1:length(sessions)
        base_events = [events.a] == sessions(i);
        base_times = -100 <= times & times < 0;
        x = squeeze(pattern(base_events,:,base_times));
        
        % average over samples in baseline period (should be 0)
        m = nanmean(nanmean(x, 1), 3);
        mlunit.assert(all(abs(m) < 0.000000000001))
        
        % average std dev over samples should be 1
        s = nanmean(nanstd(x, 1), 3);
        mlunit.assert(all(abs(1 - s) < 0.000000000001))
      end
    end
  end
end