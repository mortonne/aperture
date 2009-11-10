classdef test_cat_events < mlunit.test_case
  properties
    ev_name = 'test_cat_events';
    ev_source = 'test_source';
    res_dir = 'cat_events';
    evs
    number
  end
  
  methods
    function self = test_cat_events(varargin)
      self = self@mlunit.test_case(varargin{:});
      
      self.evs = [];
      self.number = [];
      for i=1:3
        % make an ev object for this subject with dummy events
        subj_id = sprintf('subj%02d', i);
        ev_name = sprintf('%s_events', subj_id);
        ev = init_ev(ev_name, 'source', subj_id);
        event = repmat(struct('type', 'test', 'number', i), 1, i*2);
        ev = set_mat(ev, event);
        
        % add to the list of evs
        self.evs = addobj(self.evs, ev);
        
        % save the number field to compare to the concatenated events
        self.number = [self.number [event.number]];
      end
    end
    
    function self = test_cat(self)
      [ev, events] = cat_events(self.evs, self.ev_name, self.ev_source, ...
                                self.res_dir);

      % check output events
      mlunit.assert(exist_mat(ev), 'problem with saved events.');
      
      % check output name
      mlunit.assert(strcmp(ev.name, self.ev_name), 'incorrect ev name.');
      
      % check output length
      mlunit.assert(ev.len == length(events), ...
                    'ev length doesn''t match events.');
      
      % check length against input events
      ev_lens = [self.evs.len];
      mlunit.assert(sum(ev_lens) == ev.len, ...
                    'output ev length does not equal sum of inputs.');
      
      % check the number field
      mlunit.assert(isequal([events.number], self.number), ...
                    'events field is corrupted.');
    end
  end
end
