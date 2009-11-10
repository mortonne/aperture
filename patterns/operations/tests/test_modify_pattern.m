classdef test_modify_pattern < mlunit.test_case
  properties
    ev
    event
    pat
    pattern
    pat_file = 'pattern_temp.mat';
    ev_file = 'events_temp.mat';
    res_dir = 'new_pattern';
  end
    
  methods
    function self = test_modify_pattern(varargin)
      %test = mlunit.test_case(name, 'my_test');
      %self.dummy = false;
      %self = class(self, 'my_test', test);
      
      self = self@mlunit.test_case(varargin{:});
      
      % initialize properties to be used in all tests
      self.ev = init_ev('test_events');
      self.event = repmat(struct('type', 'test'), 1, 10);
      self.pat = init_pat('test_pattern', '', 'subj007', struct, self.ev);
      self.pattern = rand(10, 1);
      
      % remove any existing files
      if exist(self.pat_file, 'file')
        delete(self.pat_file);
      end
      if exist(self.ev_file, 'file')
        delete(self.ev_file);
      end
    end
  
    function self = test_hd_overwrite(self)
      % save the pattern to disk
      pat = self.pat;
      pat.file = self.pat_file;
      pat = set_mat(pat, self.pattern);
      
      % save events to disk
      ev = self.ev;
      ev.file = self.ev_file;
      ev = set_mat(ev, self.event);
      pat.dim.ev = ev;
      
      % overwrite the old pat object
      params = struct('eventFilter', 'strcmp(type, ''test'')', ...
                      'overwrite', true);
      pat = modify_pattern(pat, params);
      
      % check locations
      mlunit.assert(strcmp(get_obj_loc(pat), 'hd'), 'pat in ws.');
      mlunit.assert(strcmp(get_obj_loc(pat.dim.ev), 'hd'), 'ev in ws.');
      
      % check files
      mlunit.assert(strcmp(self.pat_file, pat.file), 'pat in new file.');
      mlunit.assert(~strcmp(self.ev_file, pat.dim.ev.file), 'ev in old file.');

      % check modified labels
      mlunit.assert(~pat.modified, 'pat modified.');
      mlunit.assert(~pat.dim.ev.modified, 'ev modified.');
      
      delete(pat.file);
      delete(pat.dim.ev.file);
    end
    
    function self = test_hd_rename(self)
      % save the pattern to disk
      pat = self.pat;
      pat.file = self.pat_file;
      pat = set_mat(pat, self.pattern);
      
      % save events to disk
      ev = self.ev;
      ev.file = self.ev_file;
      ev = set_mat(ev, self.event);
      pat.dim.ev = ev;
      
      % save to a new pat object
      pat_name = 'test_pattern_mod';
      params = struct('eventFilter', 'strcmp(type, ''test'')', ...
                      'overwrite', true);
      pat = modify_pattern(pat, params, pat_name, self.res_dir);
      
      % check locations
      mlunit.assert(strcmp(get_obj_loc(pat), 'hd'), 'pat in ws.');
      mlunit.assert(strcmp(get_obj_loc(pat.dim.ev), 'hd'), 'ev in ws.');
      
      % check files
      mlunit.assert(~strcmp(self.pat_file, pat.file), 'pat in old file.');
      mlunit.assert(~strcmp(self.ev_file, pat.dim.ev.file), 'ev in old file.');

      % check modified labels
      mlunit.assert(~pat.modified, 'pat modified.');
      mlunit.assert(~pat.dim.ev.modified, 'ev modified.');
      
      delete(pat.file);
      delete(pat.dim.ev.file);
    end
    
    function self = test_ws_overwrite(self)
      % add events and pattern to the workspace
      pat = set_mat(self.pat, self.pattern);
      pat.dim.ev = self.ev;
      pat.dim.ev = set_mat(pat.dim.ev, self.event);
      
      % overwrite the existing matrix
      pat = modify_pattern(pat);
      
      % check locations
      mlunit.assert(strcmp(get_obj_loc(pat), 'ws'), 'pat on hd.');
      mlunit.assert(strcmp(get_obj_loc(pat.dim.ev), 'ws'), 'ev on hd.');
      
      % check modified labels
      mlunit.assert(pat.modified, 'pat not modified.');
      mlunit.assert(~pat.dim.ev.modified, 'ev modified.');
    end
    
    function self = test_ws_rename(self)
      % add events and pattern to the workspace
      pat = set_mat(self.pat, self.pattern);
      pat.dim.ev = self.ev;
      pat.dim.ev = set_mat(pat.dim.ev, self.event);
      
      % save to a new pat object with no events modifications
      pat_name = 'test_pattern_mod';
      pat = modify_pattern(pat, struct, pat_name);
      
      % check name
      mlunit.assert(strcmp(pat.name, pat_name), 'old pat name.');
      
      % check locations
      mlunit.assert(strcmp(get_obj_loc(pat), 'ws'), 'pat on hd.');
      mlunit.assert(strcmp(get_obj_loc(pat.dim.ev), 'ws'), 'ev on hd.');
      
      % check modified labels
      mlunit.assert(pat.modified, 'pat not modified.');
      mlunit.assert(~pat.dim.ev.modified, 'ev modified.');
    end
    
    function self = test_ws_rename_events(self)
      % add events and pattern to the workspace
      self.pat.dim.ev = set_mat(self.pat.dim.ev, self.event);
      pat = set_mat(self.pat, self.pattern);
      
      % save to a new pat object
      pat_name = 'test_pattern_mod';
      params = struct('eventFilter', 'strcmp(type, ''test'')');
      pat = modify_pattern(pat, params, pat_name);
      
      % check modified labels
      mlunit.assert(pat.dim.ev.modified, 'ev not modified.')
    end
  end
end

